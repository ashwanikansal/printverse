// Modal logic
function openModal(e, el) {
  e.preventDefault()
  // el could be the <a> thumb or the article card element
  const card = el.closest ? el.closest(".card") : el
  const data = card ? JSON.parse(card.getAttribute("data-art")) : null
  const img = card ? card.querySelector("img") : null

  if (data) {
    document.getElementById("modalTitle").textContent = data.name
    document.getElementById("modalAnime").textContent = `${data.anime} • A3`
    document.getElementById("modalPrice").textContent = `₹${data.price}`
    document.getElementById("modalImage").src = img ? img.src : ""
    document.getElementById("modalImage").alt = data.name
    document.getElementById("orderBtn").dataset.art = JSON.stringify(data)
  }
  document.getElementById("modalBackdrop").style.display = "flex"
  // lock scroll
  document.body.style.overflow = "hidden"
}

function closeModal(e) {
  if (e && e.target && e.target.id === "modalBackdrop") {
    /* clicked backdrop */
  }
  document.getElementById("modalBackdrop").style.display = "none"
  document.body.style.overflow = ""
}

function orderNow() {
  const btn = document.getElementById("orderBtn")
  const data = btn.dataset.art ? JSON.parse(btn.dataset.art) : null
  if (!data) return
  // Placeholder: open chatbot and prefill art selection.
  // Replace this with your chatbot widget launcher or route to /chat
  console.log(data)
  openChatbot(data.name)
  closeModal()
}

// // Placeholder chatbot opener
// function openChatbot(artName) {
//   // If you have a chat widget, call its open function here.
//   // Example: window.chatWidget.open({prefill: `I want to order ${artName}`})
//   if (artName) {
//     alert(
//       `(CHATBOT) Would open chatbot with prefilled text: "I want to buy ${artName}"`
//     )
//   } else {
//     alert("(CHATBOT) Would open chatbot now")
//   }
// }

// keyboard: ESC to close
document.addEventListener("keydown", function (e) {
  if (e.key === "Escape") {
    closeModal()
  }
})


/* ---------- CONFIG: set your iframe base URL here ---------- */
const CHAT_IFRAME_BASE = "https://bot.dialogflow.com/7a12dd70-7b1c-4286-b77e-71ff5ce33675";

/* If your widget accepts prefill via query param (e.g. ?prefill=...), set true.
   Otherwise set false and enable postMessage in your iframe app (if supported). */
const PREFILL_VIA_QUERY = false; // try true if your widget supports it

const chatWidget = document.getElementById("chatWidget");
const chatIframe = document.getElementById("chatIframe");
const chatFab = document.getElementById("chatFab");

function openChatbot(artName) {
  const prefillText = artName ? `I want to order 1 ${artName}` : "";

  // If query param prefill supported
  if (PREFILL_VIA_QUERY && prefillText) {
    try {
      const url = new URL(CHAT_IFRAME_BASE);
      url.searchParams.set("prefill", prefillText);
      chatIframe.src = url.toString();
    } catch (e) {
      // fallback if URL() fails
      chatIframe.src = CHAT_IFRAME_BASE + "?prefill=" + encodeURIComponent(prefillText);
    }
  } else {
    // ensure iframe loaded
    if (!chatIframe.src || chatIframe.src === "about:blank") {
      chatIframe.src = CHAT_IFRAME_BASE;
    }
  }

  // show widget
  chatWidget.classList.remove("closed");
  chatWidget.setAttribute("aria-hidden", "false");

  // If using postMessage prefill (iframe must implement listener)
  if (!PREFILL_VIA_QUERY && prefillText) {
    const onLoad = function() {
      try {
        // send prefill message; iframe must listen for this format
        chatIframe.contentWindow.postMessage({ type: "prefill", text: prefillText }, "*");
      } catch (err) {
        console.warn("postMessage to chatbot iframe failed:", err);
      }
      chatIframe.removeEventListener("load", onLoad);
    };
    chatIframe.addEventListener("load", onLoad);
  }
}

function closeChat() {
  chatWidget.classList.add("closed");
  chatWidget.setAttribute("aria-hidden", "true");
  // Optionally unload iframe to free resources:
  // chatIframe.src = "about:blank";
}

// attach FAB click
if (chatFab) chatFab.addEventListener("click", () => openChatbot());

// Optional: allow parent page to receive messages from iframe if needed
window.addEventListener("message", (e) => {
  // Example: if iframe sends {type:'order-complete', orderId: 'OC1001'} you can handle it
  // console.log("message from iframe:", e.data);
});

