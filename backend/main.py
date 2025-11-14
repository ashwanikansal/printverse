from fastapi import FastAPI
from fastapi import Request
from fastapi.responses import JSONResponse
import db_helper
import generic_helper

app = FastAPI()

inprogress_orders = {}

@app.post("/")
async def handle_request(request : Request):

    # Retrieve the JSON data from the request
    payload = await request.json()

    # Extract the necessary information from the payload
    # based on the structure of the WebhookRequest from Dialogflow
    intent = payload['queryResult']['intent']['displayName']
    parameters = payload['queryResult']['parameters']
    output_contexts = payload['queryResult']['outputContexts']
    session_id = generic_helper.extract_session_id(output_contexts[0]["name"])

    intent_handler_dict = {
        'order.add-context:ongoing-order': add_to_order,
        'order.remove-context:ongoing-order': remove_from_order,
        'order.complete-context:ongoing-order': complete_order,
        'track.order-context:ongoing-tracking': track_order
    }

    return intent_handler_dict[intent](parameters, session_id)

def add_to_order(parameters: dict, session_id: str):
    artworks = parameters["artwork"]
    quantities = parameters["number"]

    if len(artworks) != len(quantities):
        fulfillmentText = "Sorry I didn't understand. Can you please specify the quantities and items correctly."
    else:
        new_art_dict = dict(zip(artworks, quantities))

        if session_id in inprogress_orders:
            current_art_dict = inprogress_orders[session_id]
            current_art_dict.update(new_art_dict)
            inprogress_orders[session_id] = current_art_dict
        else:
            inprogress_orders[session_id] = new_art_dict
        
        order_str = generic_helper.get_str_from_art_dict(inprogress_orders[session_id])

        fulfillmentText = f"So far you have : {order_str}. Do you want anything else?"

    return JSONResponse(content={
            "fulfillmentText" : fulfillmentText
        })  

def remove_from_order(parameters: dict, session_id: str):
    if session_id not in inprogress_orders:
        return JSONResponse(content={
            "fulfillmentText": "I'm having a trouble finding your order. Sorry! Can you place a new order please?"
        })
    
    art_items = parameters["artwork"]
    current_order = inprogress_orders[session_id]

    removed_items = []
    no_such_items = []

    for item in art_items:
        if item not in current_order:
            no_such_items.append(item)
        else:
            removed_items.append(item)
            del current_order[item]
    

    if len(removed_items) > 0:
        fulfillment_text = f'Removed {",".join(removed_items)} from your order!'

    if len(no_such_items) > 0:
        fulfillment_text = f' Your current order does not have {",".join(no_such_items)}'

    if len(current_order.keys()) == 0:
        fulfillment_text += " Your order is empty!"
    else:
        order_str = generic_helper.get_str_from_art_dict(current_order)
        fulfillment_text += f" Here is what is left in your order: {order_str}"

    return JSONResponse(content={
        "fulfillmentText": fulfillment_text
    })

        
def complete_order(parameters: dict, session_id: str):
    print(parameters)
    if session_id not in inprogress_orders:
        fulfillmentText = "I'm having a trouble in finding your order. Sorry! Can you place a new order please?"
    else:
        order = inprogress_orders[session_id]
        order_id = save_to_db(order)

        if order_id == -1:
            fulfillmentText = "Sorry, I couldn't process your order due to a backend error." \
            "Please place a new order again." 
        else:
            order_total = db_helper.get_total_order_price(order_id)
            fulfillmentText = f"Awesome! We have placed your order." \
            f"Here is your order id #{order_id}." \
            f"Your order total is {order_total} which you can pay at the time of delivery!"
        
        del inprogress_orders[session_id]

    return JSONResponse(content={
            "fulfillmentText" : fulfillmentText
        })  

def save_to_db(order: dict):
    next_order_id = db_helper.get_next_order_id()
    for artwork, quantity in order.items():
        rcode = db_helper.insert_order_item(artwork, quantity, next_order_id)
        if rcode == -1:
            return -1
    
    db_helper.insert_order_tracking(next_order_id, "In Progress")
    return next_order_id

def track_order(parameters: dict, session_id: str):
    order_id = int(parameters['order_id'])
    order_status = db_helper.get_order_status(order_id)

    if order_status:
        fulfillmentText = f"The order status for order id: {order_id} is : {order_status}"
    else : 
        fulfillmentText = f"No order found with order id : {order_id}"

    return JSONResponse(content={
            "fulfillmentText" : fulfillmentText
        })
    