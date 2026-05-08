'use strict';

/* ═══════════════════════════════════════════════════════════
   Zero Junkies — Store UI  store.js
   Standalone store page with cart, categories, search,
   item detail modal, and checkout.
═══════════════════════════════════════════════════════════ */

function nuiPost(action, data = {}) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  }).catch(() => {});
}
function GetParentResourceName() {
  return window.GetParentResourceName ? window.GetParentResourceName() : 'zero-junkies';
}

// ── State ────────────────────────────────────────────────────────
let storeState = {
  items:        [],
  cart:         [],   // [{ item, label, price, qty, icon, category }]
  balance:      0,
  locationName: 'Smoke Shop',
  activeCategory: 'all',
  modalItem:    null,
  modalQty:     1,
};

// Item category map — matches config category field
const itemCategories = {
  weed4g:        'flower',
  weed20g:       'flower',
  weedbrick:     'flower',
  weed_pooch:    'flower',
  joint2g:       'preroll',
  blunt5g:       'preroll',
  blunt_pack:    'preroll',
  preroll_pack:  'preroll',
  edible_gummy:  'edible',
  edible_brownie:'edible',
  edible_cookie: 'edible',
  edible_drink:  'edible',
  rolpaper:      'accessories',
  lighter:       'accessories',
  grinder:       'accessories',
};

const itemIcons = {
  weed4g:        '🌱',
  weed20g:       '🌿',
  weedbrick:     '🧱',
  weed_pooch:    '👜',
  joint2g:       '🚬',
  blunt5g:       '🌀',
  blunt_pack:    '📦',
  preroll_pack:  '📦',
  edible_gummy:  '🐻',
  edible_brownie:'🍫',
  edible_cookie: '🍪',
  edible_drink:  '🥤',
  rolpaper:      '📜',
  lighter:       '🔥',
  grinder:       '⚙️',
};

// ── Toast ────────────────────────────────────────────────────────
let toastTimer;
function storeToast(msg, type = 'info') {
  const el = document.getElementById('store-toast');
  el.textContent = msg;
  el.className = 'show ' + type;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.className = ''; }, 2800);
}

// ── Open / close ─────────────────────────────────────────────────
function openStore(data) {
  storeState.items        = data.items        || [];
  storeState.balance      = data.balance      || 0;
  storeState.locationName = data.locationName || 'Smoke Shop';
  storeState.cart         = [];
  storeState.activeCategory = 'all';

  document.getElementById('store-location-name').textContent = storeState.locationName;
  document.getElementById('store-balance').textContent = '$' + storeState.balance.toLocaleString();
  document.getElementById('store-search').value = '';

  // Reset category buttons
  document.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
  document.querySelector('.cat-btn[data-cat="all"]').classList.add('active');

  renderProducts();
  renderCart();

  document.getElementById('store-overlay').classList.remove('hidden');
}

function closeStore() {
  document.getElementById('store-overlay').classList.add('hidden');
  nuiPost('closeStore', {});
}

// ── Category filter ───────────────────────────────────────────────
document.querySelectorAll('.cat-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    storeState.activeCategory = btn.dataset.cat;
    document.getElementById('store-search').value = '';
    renderProducts();
  });
});

// ── Search ────────────────────────────────────────────────────────
function filterItems() {
  renderProducts();
}

// ── Render products ───────────────────────────────────────────────
function renderProducts() {
  const grid   = document.getElementById('product-grid');
  const search = document.getElementById('store-search').value.toLowerCase().trim();
  const cat    = storeState.activeCategory;

  grid.innerHTML = '';

  const filtered = storeState.items.filter(item => {
    const matchCat    = cat === 'all' || (itemCategories[item.item] || 'misc') === cat;
    const matchSearch = !search || item.label.toLowerCase().includes(search) || (item.description || '').toLowerCase().includes(search);
    return matchCat && matchSearch;
  });

  if (filtered.length === 0) {
    grid.innerHTML = '<div style="grid-column:1/-1;text-align:center;color:var(--text-d);padding:40px;font-size:14px;">No items found</div>';
    return;
  }

  filtered.forEach(item => {
    const icon = itemIcons[item.item] || '🛒';
    const card = document.createElement('div');
    card.className = 'product-card';
    card.innerHTML = `
      <div class="p-icon">${icon}</div>
      <div class="p-name">${item.label}</div>
      <div class="p-desc">${item.description || ''}</div>
      <div class="p-price">$${item.price}</div>
      <button class="p-add-btn">+ Add</button>
    `;
    // Click card body = open detail modal
    card.addEventListener('click', (e) => {
      if (e.target.classList.contains('p-add-btn')) {
        quickAdd(item);
      } else {
        openModal(item);
      }
    });
    grid.appendChild(card);
  });
}

// ── Quick add (1 unit directly) ───────────────────────────────────
function quickAdd(item) {
  addToCart(item, 1);
  storeToast(item.label + ' added to cart', 'success');
}

// ── Cart ──────────────────────────────────────────────────────────
function addToCart(item, qty) {
  const existing = storeState.cart.find(c => c.item === item.item);
  if (existing) {
    existing.qty += qty;
  } else {
    storeState.cart.push({
      item:  item.item,
      label: item.label,
      price: item.price,
      qty:   qty,
      icon:  itemIcons[item.item] || '🛒',
    });
  }
  renderCart();
}

function removeFromCart(itemName) {
  storeState.cart = storeState.cart.filter(c => c.item !== itemName);
  renderCart();
}

function clearCart() {
  storeState.cart = [];
  renderCart();
}

function renderCart() {
  const container = document.getElementById('cart-items');
  container.innerHTML = '';

  let total = 0;
  storeState.cart.forEach(entry => {
    const lineTotal = entry.price * entry.qty;
    total += lineTotal;
    const el = document.createElement('div');
    el.className = 'cart-item';
    el.innerHTML = `
      <span>${entry.icon}</span>
      <span class="cart-item-name">${entry.label}</span>
      <span class="cart-item-qty">×${entry.qty}</span>
      <span class="cart-item-price">$${lineTotal}</span>
      <span class="cart-item-rm" title="Remove">✕</span>
    `;
    el.querySelector('.cart-item-rm').addEventListener('click', () => removeFromCart(entry.item));
    container.appendChild(el);
  });

  document.getElementById('cart-total').textContent = '$' + total.toLocaleString();

  // Disable checkout if cart empty or insufficient funds
  const btn = document.getElementById('checkout-btn');
  btn.disabled = storeState.cart.length === 0 || total > storeState.balance;
  btn.style.opacity = btn.disabled ? '.4' : '1';
  btn.style.cursor  = btn.disabled ? 'not-allowed' : 'pointer';
}

// ── Checkout ──────────────────────────────────────────────────────
function checkout() {
  if (storeState.cart.length === 0) return;

  const total = storeState.cart.reduce((s, c) => s + c.price * c.qty, 0);
  if (total > storeState.balance) {
    storeToast('Not enough cash!', 'error');
    return;
  }

  // Send each cart item to server
  nuiPost('storePurchaseCart', { cart: storeState.cart });

  // Show flash confirmation
  const flash = document.getElementById('purchase-flash');
  document.getElementById('purchase-flash-msg').textContent =
    'Purchased ' + storeState.cart.length + ' item(s) for $' + total.toLocaleString();
  flash.classList.remove('hidden');
  setTimeout(() => flash.classList.add('hidden'), 1700);

  // Update balance display
  storeState.balance -= total;
  document.getElementById('store-balance').textContent = '$' + storeState.balance.toLocaleString();

  storeState.cart = [];
  renderCart();
}

// ── Item detail modal ─────────────────────────────────────────────
function openModal(item) {
  storeState.modalItem = item;
  storeState.modalQty  = 1;

  document.getElementById('modal-icon').textContent  = itemIcons[item.item] || '🛒';
  document.getElementById('modal-name').textContent  = item.label;
  document.getElementById('modal-desc').textContent  = item.description || '';
  document.getElementById('modal-price').textContent = '$' + item.price + ' each';
  updateModalSubtotal();

  document.getElementById('item-modal').classList.remove('hidden');
}

function closeModal() {
  document.getElementById('item-modal').classList.add('hidden');
  storeState.modalItem = null;
}

function modalQty(delta) {
  storeState.modalQty = Math.max(1, Math.min(99, storeState.modalQty + delta));
  document.getElementById('modal-qty').textContent = storeState.modalQty;
  updateModalSubtotal();
}

function updateModalSubtotal() {
  const item = storeState.modalItem;
  if (!item) return;
  const sub = item.price * storeState.modalQty;
  document.getElementById('modal-subtotal').textContent = 'Subtotal: $' + sub.toLocaleString();
}

function modalAddToCart() {
  const item = storeState.modalItem;
  if (!item) return;
  addToCart(item, storeState.modalQty);
  storeToast(storeState.modalQty + 'x ' + item.label + ' added', 'success');
  closeModal();
}

// Close modal on backdrop click
document.getElementById('item-modal').addEventListener('click', (e) => {
  if (e.target === document.getElementById('item-modal')) closeModal();
});

// ── Message listener ──────────────────────────────────────────────
window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.type) return;

  if (data.type === 'openStore') {
    openStore(data);
  }
  if (data.type === 'closeStore') {
    closeStore();
  }
  if (data.type === 'storeUpdateBalance') {
    storeState.balance = data.balance || 0;
    document.getElementById('store-balance').textContent = '$' + storeState.balance.toLocaleString();
    renderCart();
  }
  if (data.type === 'storePurchaseResult') {
    if (data.success) {
      storeToast('Purchase complete!', 'success');
    } else {
      storeToast(data.message || 'Purchase failed.', 'error');
    }
  }
});

// ESC closes store
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    if (!document.getElementById('item-modal').classList.contains('hidden')) {
      closeModal();
    } else {
      closeStore();
    }
  }
});
