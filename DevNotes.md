# Printverse Art Chatbot – Developer Notes

## 1. Dialogflow Setup

### Login and Create Agent
1. Log in to Dialogflow ES.
2. Create a new agent named: chopper-chatbot-for-art-orders


---

## 2. Intents Configuration

Dialogflow automatically expands the training phrases you provide by using its built-in ML model.  
The following intents were created:

### System Intents
- **Default Welcome Intent**  
- **Default Fallback Intent**

### Custom Intents
- **new.order**
- **order.add**  
  - Contains required entities (e.g., artwork, quantity)
- **order.remove**
- **track.order**

---

## 3. Entities

### Created Entity:
- **artwork**

This entity holds the list of artworks users can order.

---

## 4. Contexts

The following contexts were created to manage flow:

- **ongoing-order**  
- **ongoing-tracking**

These help Dialogflow maintain short-term conversational context.

---

## 5. Database Setup

A MySQL database is used for storing artwork and order details.  
Tables created:

- **artworks**  
- **order_tracking**  
- **orders**

These tables collectively store available products, user orders, and order status.

---

## 6. Backend Setup (FastAPI)

### Install Python
Ensure Python is installed on your system.

### Create a Virtual Environment (VS Code)
1. Press `Ctrl + Shift + P`
2. Choose: **Python: Create Environment**
3. Select your Python version

### Install Dependencies
```bash
pip install fastapi[all]
pip install mysql-connector-python
```
Or install from a requirements file:
```bash
pip install -r requirements.txt
```

### Create Backend Files

1. Create a main.py file and add the API/webhook logic.
2. Create a db_helper.py file to manage database connections.
3. Run the Backend
```bash
uvicorn main:app --reload
```


---

## 7. Connecting Dialogflow to Backend (Webhook Setup)

Dialogflow requires an HTTPS webhook URL.

Since http://localhost:8000 is not accepted directly, we use ngrok:

1. Install ngrok.
2. Run:
```bash
ngrok http 8000
```
3. Copy the generated HTTPS URL.
4. Paste it into Dialogflow → Fulfillment → Webhook URL.

### How Webhook Fulfillment Works

For any intent where backend processing is required:

1. Enable Webhook Fulfillment for that intent.
2. When triggered, Dialogflow sends the request to your webhook URL.
3. The backend processes the request and returns a response, which Dialogflow delivers to the user.


---

## 8. Backend Session Management

Dialogflow does not store long-term memory between messages.
To handle multi-step flows, the backend maintains an internal dictionary.

Example structure:
```python
{
  session_id: {
      items: {
          artwork_name: quantity
      }
  }
}
```
Session IDs are extracted from the Dialogflow webhook request, typically from outputContexts.
A helper function is created in a utility file to extract and manage session IDs.


---

## 9. Frontend integration

Iframe is used given by Dialogflow.