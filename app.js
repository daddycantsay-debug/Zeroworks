/* ═══════════════════════════════════════════════════════════
   Zero Junkies — Tablet UI  app.js
   Receives messages from Lua via SendNUIMessage.
   Sends actions back via fetch POST to the NUI callback.
═══════════════════════════════════════════════════════════ */

'use strict';

// ── NUI callback helper ──────────────────────────────────────────
function nuiPost(action, data = {}) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  }).catch(() => {});
}

// Fallback for browser testing
function GetParentResourceName() {
  return window.GetParentResourceName ? window.GetParentResourceName() : 'zero-junkies';
}

// ── Toast notification ───────────────────────────────────────────
let toastTimer = null;
function showToast(msg, type = 'info') {
  let el = document.getElementById('toast');
  if (!el) {
    el = document.createElement('div');
    el.id = 'toast';
    document.body.appendChild(el);
  }
  el.textContent = msg;
  el.className = 'show ' + type;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.className = ''; }, 3000);
}

// ── State ────────────────────────────────────────────────────────
let state = {
  view:          'list',
  mood:          0,       // -3 to +3
  buyerName:     'Buyer',
  buyerLabel:    'Buyer',
  drugs:         [],
  dialogueOpts:  [],
  trunkLabActive: false,
  trunkLabVeh:   false,
  craftRecipes:  [],
  contacts:      [],
  storeItems:    [],
  activeDelivery: null,
  rollActive:    false,
  rollSequence:  [],
  rollStep:      0,
  rollSteps:     4,
};

// ── View management ──────────────────────────────────────────────
function showView(name) {
  document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
  const el = document.getElementById('view-' + name);
  if (el) el.classList.add('active');
  state.view = name;
}

function switchTab(name) {
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  const btn = document.querySelector(`.tab-btn[data-tab="${name}"]`);
  if (btn) btn.classList.add('active');

  const viewMap = {
    main:   'list',
    drugs:  'drugs',
    craft:  'craft',
    phone:  'phone',
    store:  'store',
  };
  showView(viewMap[name] || 'list');
}

// ── Open / close tablet ──────────────────────────────────────────
function openTablet(data) {
  document.getElementById('overlay').classList.remove('hidden');

  // Set status bar mood
  updateMoodDisplay(data.mood || 0);

  // Show/hide tab bar
  const tabBar = document.getElementById('tab-bar');
  if (data.showTabs) {
    tabBar.classList.remove('hidden');
  } else {
    tabBar.classList.add('hidden');
  }

  // Route to correct view
  const view = data.view || 'list';
  showView(view);

  // Populate based on view
  if (view === 'list')      renderList(data);
  if (view === 'drugs')     renderDrugs(data);
  if (view === 'dialogue')  renderDialogue(data);
  if (view === 'trunk')     renderTrunk(data);
  if (view === 'craft')     renderCraft(data);
  if (view === 'phone')     renderPhone(data);
  if (view === 'store')     renderStore(data);
  if (view === 'roll')      renderRoll(data);
}

function closeTablet() {
  document.getElementById('overlay').classList.add('hidden');
  nuiPost('closeTablet', {});
}

// ── Mood display ─────────────────────────────────────────────────
const moodLabels = {
  '-3': { label: 'Hostile',    color: '#ff2244', pct: 5  },
  '-2': { label: 'Hostile',    color: '#ff2244', pct: 15 },
  '-1': { label: 'Annoyed',    color: '#ff6b00', pct: 30 },
   '0': { label: 'Neutral',    color: '#d4dbe8', pct: 50 },
   '1': { label: 'Relaxed',    color: '#39ff14', pct: 65 },
   '2': { label: 'Friendly',   color: '#39ff14', pct: 80 },
   '3': { label: 'Friendly',   color: '#39ff14', pct: 95 },
};

function updateMoodDisplay(mood) {
  state.mood = mood;
  const m = moodLabels[String(mood)] || moodLabels['0'];
  const fill  = document.getElementById('mood-fill');
  const label = document.getElementById('mood-label');
  const statusMood = document.getElementById('status-mood');
  const dlgLabel   = document.getElementById('dialogue-mood-label');

  if (fill)  { fill.style.width = m.pct + '%'; fill.style.background = m.color; }
  if (label) { label.textContent = m.label; label.style.color = m.color; }
  if (statusMood) statusMood.textContent = 'MOOD: ' + m.label;
  if (dlgLabel)   { dlgLabel.textContent = m.label; dlgLabel.style.color = m.color; }
}

// ── Drug icons map ───────────────────────────────────────────────
const drugIcons = {
  weedbrick: '🧱', weed20g: '🌿', weed4g: '🌱', joint2g: '🚬',
  weed_pooch: '👜', shroom_pouch: '🍄', coke10g: '❄️', crack_pouch: '💎',
  meth10g: '🔬', meth_pooch: '🧪', flakka: '⚡', mdp2p: '🧫',
  spice_pooch: '🌶️', xpills: '💊', molly_pouch: '🟣', perc_pouch: '🔵',
  vicodin: '⚪', reddextro: '🔴', double_cup: '🥤', sizzurup: '🍹',
  blacktar: '🖤', morphine: '💉', opium_pouch: '🌸', speedball: '☠️',
};

// ── RENDER: Generic list ─────────────────────────────────────────
function renderList(data) {
  document.getElementById('list-header').textContent   = data.title    || '';
  document.getElementById('list-subtitle').textContent = data.subtitle || '';
  const container = document.getElementById('list-items');
  container.innerHTML = '';

  (data.items || []).forEach(item => {
    const el = document.createElement('div');
    el.className = 'list-item' +
      (item.disabled ? ' disabled' : '') +
      (item.danger   ? ' danger'   : '');

    el.innerHTML = `
      <div class="item-icon">${item.icon || '▸'}</div>
      <div class="item-body">
        <div class="item-label">${item.label}</div>
        ${item.desc ? `<div class="item-desc">${item.desc}</div>` : ''}
      </div>
      ${item.badge ? `<div class="item-badge ${item.badgeClass || ''}">${item.badge}</div>` : ''}
    `;

    if (!item.disabled) {
      el.addEventListener('click', () => {
        nuiPost('listAction', { action: item.action, args: item.args || {} });
      });
    }
    container.appendChild(el);
  });
}

// ── RENDER: Sell menu ────────────────────────────────────────────
function renderDrugs(data) {
  updateMoodDisplay(data.mood || 0);
  state.drugs = data.drugs || [];
  state.buyerName  = data.buyerName  || 'Buyer';
  state.buyerLabel = data.buyerLabel || 'Buyer';

  const grid = document.getElementById('drug-grid');
  grid.innerHTML = '';

  state.drugs.forEach((drug, i) => {
    const card = document.createElement('div');
    card.className = 'drug-card' + (drug.preferred ? ' preferred' : '');
    const icon = drugIcons[drug.item] || '💊';
    card.innerHTML = `
      <div class="drug-icon">${icon}</div>
      <div class="drug-name">${drug.label}</div>
      <div class="drug-price">$${drug.minPrice}–$${drug.maxPrice}</div>
    `;
    card.addEventListener('click', () => {
      nuiPost('sellDrug', { index: i + 1, moodMult: data.moodMult || 1.0 });
      closeTablet();
    });
    grid.appendChild(card);
  });

  // Dismiss button
  const dismiss = document.createElement('div');
  dismiss.className = 'drug-card';
  dismiss.style.gridColumn = '1 / -1';
  dismiss.style.textAlign = 'center';
  dismiss.style.borderColor = '#ff2244';
  dismiss.innerHTML = `<div class="drug-name" style="color:#ff2244">❌ Never mind</div>`;
  dismiss.addEventListener('click', () => {
    nuiPost('dismissBuyer', {});
    closeTablet();
  });
  grid.appendChild(dismiss);
}

// ── RENDER: Dialogue ─────────────────────────────────────────────
function renderDialogue(data) {
  updateMoodDisplay(data.mood || 0);
  document.getElementById('dialogue-buyer-name').textContent = data.buyerLabel || 'Buyer';

  const container = document.getElementById('dialogue-options');
  container.innerHTML = '';

  const opts = [
    { icon: '👋', label: 'Say hey',            topic: 'greeting',  cls: '' },
    { icon: '💰', label: 'Negotiate price',     topic: 'price',     cls: '' },
    { icon: '🔬', label: 'Ask about quality',   topic: 'quality',   cls: '' },
    { icon: '👮', label: 'Ask about heat',      topic: 'heat',      cls: '' },
    { icon: '💬', label: 'Small talk',          topic: 'smalltalk', cls: '' },
    { icon: '🛒', label: 'Make the deal',       topic: 'sell',      cls: 'sell-btn' },
    { icon: '❌', label: 'Send them away',      topic: 'dismiss',   cls: 'dismiss-btn' },
  ];

  opts.forEach(opt => {
    const btn = document.createElement('button');
    btn.className = 'dialogue-btn ' + opt.cls;
    btn.innerHTML = `<span>${opt.icon}</span> ${opt.label}`;
    btn.addEventListener('click', () => {
      if (opt.topic === 'sell') {
        nuiPost('openSell', {});
        closeTablet();
      } else if (opt.topic === 'dismiss') {
        nuiPost('dismissBuyer', {});
        closeTablet();
      } else {
        nuiPost('dialogue', { topic: opt.topic });
        closeTablet();
      }
    });
    container.appendChild(btn);
  });
}

// ── RENDER: Trunk menu ───────────────────────────────────────────
function renderTrunk(data) {
  state.trunkLabActive = data.labActive || false;

  const statusEl = document.getElementById('trunk-lab-status');
  if (data.labActive) {
    statusEl.textContent = '🔬 Trunk Lab ACTIVE — 2x craft speed';
    statusEl.className = 'active';
  } else if (data.labInstalled) {
    statusEl.textContent = '🔬 Trunk Lab installed — park vehicle to activate';
    statusEl.className = '';
  } else {
    statusEl.textContent = '🔧 No lab installed — buy kit from YouTools ($2,500)';
    statusEl.className = '';
  }

  const container = document.getElementById('trunk-options');
  container.innerHTML = '';

  const opts = [
    { icon: '🔓', label: 'Open Trunk',       desc: 'Pop the boot',                          action: 'trunkOpen'    },
    { icon: '🧪', label: 'Craft Drugs',       desc: data.labActive ? '2x speed active' : 'Use ingredients to make product', action: 'trunkCraft' },
    { icon: '💊', label: 'Sell From Trunk',   desc: 'Start selling — buyers approach car',   action: 'trunkSell'    },
    { icon: '🔧', label: 'Install Trunk Lab', desc: data.labInstalled ? 'Already installed' : 'Requires kit from YouTools', action: 'trunkInstall', disabled: data.labInstalled },
    { icon: '❌', label: 'Close',             desc: '',                                       action: 'trunkClose',  danger: true },
  ];

  opts.forEach(opt => {
    const el = document.createElement('div');
    el.className = 'list-item' + (opt.disabled ? ' disabled' : '') + (opt.danger ? ' danger' : '');
    el.innerHTML = `
      <div class="item-icon">${opt.icon}</div>
      <div class="item-body">
        <div class="item-label">${opt.label}</div>
        ${opt.desc ? `<div class="item-desc">${opt.desc}</div>` : ''}
      </div>
    `;
    if (!opt.disabled) {
      el.addEventListener('click', () => {
        nuiPost(opt.action, {});
        if (opt.action !== 'trunkCraft') closeTablet();
      });
    }
    container.appendChild(el);
  });
}

// ── RENDER: Craft menu ───────────────────────────────────────────
function renderCraft(data) {
  state.craftRecipes = data.recipes || [];
  const labActive = data.labActive || false;

  const tagEl = document.getElementById('craft-lab-tag');
  tagEl.textContent = labActive ? '🔬 LAB ACTIVE — 2x speed' : '';

  const list = document.getElementById('craft-list');
  list.innerHTML = '';

  state.craftRecipes.forEach((recipe, i) => {
    const card = document.createElement('div');
    card.className = 'craft-card';
    const ingStr = recipe.ingredients.map(ing => `${ing.amount}x ${ing.item}`).join(' + ');
    const time   = labActive
      ? Math.floor(recipe.craftTime / 2000)
      : Math.floor(recipe.craftTime / 1000);

    card.innerHTML = `
      <div class="craft-name">${recipe.label}
        <span class="craft-time">⏱ ${time}s</span>
      </div>
      <div class="craft-ingredients">Needs: ${ingStr}</div>
      <div class="craft-output">→ ${recipe.outputAmt}x ${recipe.output}</div>
    `;
    card.addEventListener('click', () => {
      nuiPost('craftDrug', { recipeIndex: i + 1 });
      startCraftProgress(recipe.label, labActive ? recipe.craftTime / 2 : recipe.craftTime);
    });
    list.appendChild(card);
  });
}

function startCraftProgress(label, duration) {
  const wrap  = document.getElementById('craft-progress-wrap');
  const lbl   = document.getElementById('craft-progress-label');
  const fill  = document.getElementById('craft-progress-fill');
  wrap.classList.remove('hidden');
  lbl.textContent = 'Crafting: ' + label;
  fill.style.transition = 'none';
  fill.style.width = '0%';
  setTimeout(() => {
    fill.style.transition = `width ${duration}ms linear`;
    fill.style.width = '100%';
  }, 50);
  setTimeout(() => {
    wrap.classList.add('hidden');
    fill.style.width = '0%';
  }, duration + 200);
}

// ── RENDER: Phone ────────────────────────────────────────────────
const contactIcons = {
  home: '🏠', office: '🏢', corner: '🚦', hotel: '🏨',
};

function renderPhone(data) {
  state.contacts = data.contacts || [];
  state.activeDelivery = data.activeDelivery || null;

  const banner = document.getElementById('active-delivery-banner');
  if (state.activeDelivery) {
    const d = state.activeDelivery;
    banner.classList.remove('hidden');
    banner.textContent = `📦 Active: ${d.amount}x ${d.drugLabel} → ${d.location}  $${d.pay}  [${d.remaining}s left]`;
  } else {
    banner.classList.add('hidden');
  }

  const list = document.getElementById('contact-list');
  list.innerHTML = '';

  state.contacts.forEach((c, i) => {
    const card = document.createElement('div');
    card.className = 'contact-card';
    const icon = contactIcons[c.type] || '📦';
    card.innerHTML = `
      <div class="contact-avatar">${icon}</div>
      <div class="contact-info">
        <div class="contact-name">${c.name}  <span style="color:var(--text-dim);font-size:11px">${c.number}</span></div>
        <div class="contact-desc">${c.description}</div>
      </div>
      <div class="contact-pay">$${c.minPay}–$${c.maxPay}</div>
    `;
    card.addEventListener('click', () => {
      nuiPost('callContact', { contactIndex: i + 1 });
      closeTablet();
    });
    list.appendChild(card);
  });
}

// ── RENDER: Weed store ───────────────────────────────────────────
const storeIcons = {
  weed4g: '🌱', weed20g: '🌿', rolpaper: '📜', joint2g: '🚬',
  lighter: '🔥', weed_pooch: '👜',
};

function renderStore(data) {
  state.storeItems = data.items || [];
  const grid = document.getElementById('store-grid');
  grid.innerHTML = '';

  state.storeItems.forEach((item, i) => {
    const card = document.createElement('div');
    card.className = 'store-card';
    const icon = storeIcons[item.item] || '🛒';
    card.innerHTML = `
      <div class="store-card-icon">${icon}</div>
      <div class="store-card-name">${item.label}</div>
      <div class="store-card-desc">${item.description}</div>
      <div class="store-card-price">$${item.price}</div>
    `;
    card.addEventListener('click', () => {
      nuiPost('buyStoreItem', { index: i + 1 });
      showToast('Buying ' + item.label + '...', 'info');
    });
    grid.appendChild(card);
  });
}

// ── RENDER: Roll minigame ────────────────────────────────────────
function renderRoll(data) {
  state.rollSequence = data.sequence || [];
  state.rollStep     = 0;
  state.rollSteps    = data.steps || 4;
  state.rollActive   = true;

  document.getElementById('roll-instruction').textContent =
    'Press the highlighted key before time runs out!';

  renderRollSteps();
  advanceRollStep();
}

function renderRollSteps() {
  const container = document.getElementById('roll-steps');
  container.innerHTML = '';
  for (let i = 0; i < state.rollSteps; i++) {
    const el = document.createElement('div');
    el.className = 'roll-step' + (i === state.rollStep ? ' current' : '');
    el.id = 'roll-step-' + i;
    el.textContent = i + 1;
    container.appendChild(el);
  }
}

function advanceRollStep() {
  if (state.rollStep >= state.rollSteps) return;

  const keyLabel = state.rollSequence[state.rollStep] || '?';
  document.getElementById('roll-key-display').textContent = keyLabel;

  // Timer bar
  const fill = document.getElementById('roll-timer-fill');
  fill.style.transition = 'none';
  fill.style.width = '100%';
  setTimeout(() => {
    fill.style.transition = 'width 2.5s linear';
    fill.style.width = '0%';
  }, 50);

  // Update step indicators
  document.querySelectorAll('.roll-step').forEach((el, i) => {
    el.className = 'roll-step' + (i < state.rollStep ? ' done' : i === state.rollStep ? ' current' : '');
  });
}

// Called from Lua when a step is completed
function rollStepResult(success) {
  const stepEl = document.getElementById('roll-step-' + state.rollStep);
  if (stepEl) stepEl.className = 'roll-step ' + (success ? 'done' : 'failed');

  if (!success) {
    document.getElementById('roll-key-display').textContent = '✗';
    document.getElementById('roll-key-display').style.color = '#ff2244';
    state.rollActive = false;
    return;
  }

  state.rollStep++;
  if (state.rollStep < state.rollSteps) {
    setTimeout(advanceRollStep, 300);
  } else {
    document.getElementById('roll-key-display').textContent = '✓';
    document.getElementById('roll-key-display').style.color = '#39ff14';
    state.rollActive = false;
  }
}

// ── Message listener (from Lua SendNUIMessage) ───────────────────
window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.type) return;

  switch (data.type) {

    case 'openTablet':
      openTablet(data);
      break;

    case 'closeTablet':
      closeTablet();
      break;

    case 'updateMood':
      updateMoodDisplay(data.mood);
      break;

    case 'rollStepResult':
      rollStepResult(data.success);
      break;

    case 'craftProgress':
      startCraftProgress(data.label, data.duration);
      break;

    case 'toast':
      showToast(data.message, data.style || 'info');
      break;

    case 'updateDelivery':
      state.activeDelivery = data.delivery;
      const banner = document.getElementById('active-delivery-banner');
      if (data.delivery) {
        const d = data.delivery;
        banner.classList.remove('hidden');
        banner.textContent = `📦 Active: ${d.amount}x ${d.drugLabel} → ${d.location}  $${d.pay}  [${d.remaining}s left]`;
      } else {
        banner.classList.add('hidden');
      }
      break;
  }
});

// ── Keyboard: ESC closes tablet ──────────────────────────────────
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeTablet();
});
