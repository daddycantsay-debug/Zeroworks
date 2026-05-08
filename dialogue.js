'use strict';

/* ═══════════════════════════════════════════════════════════
   Zero Junkies — Dialogue UI  dialogue.js
   Features:
   • Typewriter NPC speech with blinking cursor
   • Conversation history log (fades previous lines)
   • Mood ring + bar with animated transitions
   • Keyboard shortcuts: 1-7 pick options, ESC closes
   • Option flash + player bubble on selection
   • Mood flash animation on mood change
═══════════════════════════════════════════════════════════ */

// ── NUI helper ───────────────────────────────────────────────────
function nuiPost(action, data = {}) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  }).catch(() => {});
}
function GetParentResourceName() {
  return window.GetParentResourceName
    ? window.GetParentResourceName()
    : 'zero-junkies';
}

// ── Buyer type icons ─────────────────────────────────────────────
const BUYER_ICONS = {
  'Street Junkie':       '😰',
  'College Kid':         '🎓',
  'Rich Addict':         '💼',
  'Gang Member':         '🔫',
  'Biker':               '🏍️',
  'Desperate Housewife': '💊',
  'Homeless Guy':        '🏚️',
  'Off-Duty Cop':        '🚔',
  'Party Girl':          '🎉',
  'Construction Worker': '🦺',
  'Lean Sipper':         '🥤',
  'Heroin Addict':       '💉',
  'Pill Popper':         '💊',
  'Spice Head':          '🌶️',
};

// ── Mood config ──────────────────────────────────────────────────
const MOOD = {
  '-3': { label: 'Hostile',  color: '#ff1f3d', pct: 5,  ring: 'hostile'  },
  '-2': { label: 'Hostile',  color: '#ff1f3d', pct: 15, ring: 'hostile'  },
  '-1': { label: 'Annoyed',  color: '#ff8c00', pct: 30, ring: 'annoyed'  },
   '0': { label: 'Neutral',  color: '#4a5568', pct: 50, ring: 'neutral'  },
   '1': { label: 'Relaxed',  color: '#3dff6e', pct: 65, ring: 'relaxed'  },
   '2': { label: 'Friendly', color: '#3dff6e', pct: 80, ring: 'friendly' },
   '3': { label: 'Friendly', color: '#3dff6e', pct: 95, ring: 'friendly' },
};

// ── State ────────────────────────────────────────────────────────
const S = {
  open:       false,
  buyerName:  'Buyer',
  buyerLabel: 'Unknown',
  mood:       0,
  options:    [],
  typing:     false,
  history:    [],   // [{ who: 'npc'|'player', text }]
  kbIndex:    -1,
};

// ── DOM refs ─────────────────────────────────────────────────────
const $ = id => document.getElementById(id);

// ── Open dialogue ────────────────────────────────────────────────
function openDialogue(data) {
  S.open       = true;
  S.buyerName  = data.buyerName  || 'Buyer';
  S.buyerLabel = data.buyerLabel || 'Unknown';
  S.mood       = data.mood       || 0;
  S.history    = [];
  S.kbIndex    = -1;

  $('dlg-npc-icon').textContent = BUYER_ICONS[S.buyerLabel] || '👤';
  $('dlg-npc-name').textContent = S.buyerName;
  $('dlg-npc-type').textContent = S.buyerLabel;

  setMood(S.mood, false);

  $('dlg-npc-bubble').classList.add('hidden');
  $('dlg-player-bubble').classList.add('hidden');
  $('dlg-history').innerHTML = '';

  S.options = data.options || buildOptions(S.mood);
  renderOptions(S.options);

  $('dlg-overlay').classList.remove('hidden');

  // Show greeting line after a short delay
  if (data.greetLine) {
    setTimeout(() => showNpcLine(data.greetLine), 350);
  }
}

// ── Close ────────────────────────────────────────────────────────
function closeDlg() {
  $('dlg-overlay').classList.add('hidden');
  S.open = false;
  nuiPost('closeDlg', {});
}

// ── Mood ─────────────────────────────────────────────────────────
function setMood(mood, flash) {
  S.mood = mood;
  const m = MOOD[String(mood)] || MOOD['0'];

  $('dlg-mood-bar-fill').style.width      = m.pct + '%';
  $('dlg-mood-bar-fill').style.background = m.color;
  $('dlg-mood-text').textContent          = m.label;
  $('dlg-mood-text').style.color          = m.color;

  const ring = $('dlg-npc-mood-ring');
  ring.className = m.ring;
  if (flash) {
    ring.classList.add('flash');
    setTimeout(() => ring.classList.remove('flash'), 450);
  }
}

// ── Typewriter NPC line ──────────────────────────────────────────
let typeTimer = null;

function showNpcLine(text) {
  // Push previous bubble to history
  const prev = $('dlg-npc-bubble-text').textContent;
  if (prev && prev.trim()) pushHistory('npc', prev);

  const bubble = $('dlg-npc-bubble');
  const textEl = $('dlg-npc-bubble-text');

  bubble.classList.remove('hidden');
  textEl.classList.remove('done');
  textEl.textContent = '';

  clearTimeout(typeTimer);
  S.typing = true;

  let i = 0;
  const speed = 26;

  function tick() {
    if (i < text.length) {
      textEl.textContent += text[i++];
      typeTimer = setTimeout(tick, speed);
    } else {
      textEl.classList.add('done');
      S.typing = false;
    }
  }
  tick();
}

// ── Player bubble ────────────────────────────────────────────────
function showPlayerLine(text) {
  // Push previous player bubble to history
  const prev = $('dlg-player-bubble-text').textContent;
  if (prev && prev.trim()) pushHistory('player', prev);

  const bubble = $('dlg-player-bubble');
  bubble.classList.remove('hidden');
  $('dlg-player-bubble-text').textContent = text;
}

// ── History log ──────────────────────────────────────────────────
function pushHistory(who, text) {
  S.history.push({ who, text });

  const container = $('dlg-history');
  const el = document.createElement('div');
  el.className = who === 'npc' ? 'hist-npc' : 'hist-player';
  el.textContent = (who === 'npc' ? S.buyerName : 'You') + ': ' + text;
  container.appendChild(el);

  // Keep max 6 history lines
  while (container.children.length > 6) {
    container.removeChild(container.firstChild);
  }
  container.scrollTop = container.scrollHeight;
}

// ── Render options ───────────────────────────────────────────────
function renderOptions(opts) {
  const container = $('dlg-options');
  container.innerHTML = '';
  S.kbIndex = -1;

  opts.forEach((opt, i) => {
    const el = document.createElement('div');
    el.className = 'dlg-opt'
      + (opt.cls      ? ' ' + opt.cls : '')
      + (opt.disabled ? ' disabled'   : '');
    el.style.animationDelay = (i * 35) + 'ms';
    el.dataset.index = i;

    el.innerHTML = `
      <div class="dlg-opt-num">${i + 1}</div>
      <div class="dlg-opt-icon">${opt.icon || '▸'}</div>
      <div class="dlg-opt-body">
        <div class="dlg-opt-label">${opt.label}</div>
        ${opt.sub ? `<div class="dlg-opt-sub">${opt.sub}</div>` : ''}
      </div>
      ${opt.badge
        ? `<div class="dlg-opt-badge ${opt.badgeCls || 'badge-green'}">${opt.badge}</div>`
        : ''}
    `;

    if (!opt.disabled) {
      el.addEventListener('click', () => pickOption(opt, el));
    }
    container.appendChild(el);
  });
}

// ── Pick an option ───────────────────────────────────────────────
function pickOption(opt, el) {
  // Flash the selected option
  el.classList.add('selected');
  setTimeout(() => el.classList.remove('selected'), 420);

  // Show player's line
  if (opt.playerLine) showPlayerLine(opt.playerLine);

  // Briefly dim other options
  document.querySelectorAll('.dlg-opt').forEach(o => {
    if (o !== el) o.style.opacity = '.35';
  });
  setTimeout(() => {
    document.querySelectorAll('.dlg-opt').forEach(o => o.style.opacity = '');
  }, 500);

  // Fire NUI callback
  nuiPost('dlgOption', {
    topic:  opt.topic  || null,
    action: opt.action || null,
    args:   opt.args   || {},
  });

  // Close if terminal
  if (opt.closes) setTimeout(closeDlg, 900);
}

// ── Keyboard navigation ──────────────────────────────────────────
document.addEventListener('keydown', e => {
  if (!S.open) return;

  if (e.key === 'Escape') { closeDlg(); return; }

  // Click to skip typewriter
  if (e.key === ' ' && S.typing) {
    clearTimeout(typeTimer);
    const textEl = $('dlg-npc-bubble-text');
    // Fill remaining text — we don't have the full string here,
    // so just mark as done
    textEl.classList.add('done');
    S.typing = false;
    return;
  }

  const n = parseInt(e.key);
  if (n >= 1 && n <= 9) {
    const opts = document.querySelectorAll('.dlg-opt:not(.disabled)');
    if (opts[n - 1]) opts[n - 1].click();
  }
});

// ── Default options builder ──────────────────────────────────────
function buildOptions(mood) {
  return [
    {
      icon:       '👋',
      label:      'Say hey',
      sub:        'Break the ice',
      topic:      'greeting',
      playerLine: "Hey, what's good?",
    },
    {
      icon:       '💰',
      label:      'Negotiate price',
      sub:        mood >= 1 ? 'They seem open to it' : 'Risky — mood is low',
      topic:      'price',
      playerLine: 'Come on, hook me up with a deal.',
      badge:      mood >= 1 ? 'Likely' : 'Risky',
      badgeCls:   mood >= 1 ? 'badge-green' : 'badge-orange',
    },
    {
      icon:       '🔬',
      label:      'Ask about quality',
      sub:        'Make sure the product is clean',
      topic:      'quality',
      playerLine: 'This the same stuff as last time?',
    },
    {
      icon:       '👮',
      label:      'Ask about heat',
      sub:        'Check if the area is safe',
      topic:      'heat',
      playerLine: 'Cops been around here lately?',
    },
    {
      icon:       '💬',
      label:      'Small talk',
      sub:        'Keep it casual',
      topic:      'smalltalk',
      playerLine: "How's business been?",
    },
    {
      icon:       '🛒',
      label:      'Make the deal',
      sub:        'Open the sell menu',
      topic:      'sell',
      cls:        'sell-opt',
      playerLine: "Alright, let's do this.",
    },
    {
      icon:       '❌',
      label:      'Send them away',
      sub:        'End the conversation',
      topic:      'dismiss',
      cls:        'quit-opt',
      playerLine: 'Not today. Get out.',
      closes:     true,
    },
  ];
}

// ── Message listener ─────────────────────────────────────────────
window.addEventListener('message', ({ data }) => {
  if (!data || !data.type) return;

  switch (data.type) {
    case 'openDialogue':
      openDialogue(data);
      break;

    case 'closeDialogue':
      closeDlg();
      break;

    case 'npcLine':
      showNpcLine(data.text || '');
      break;

    case 'playerLine':
      showPlayerLine(data.text || '');
      break;

    case 'updateMood':
      setMood(data.mood, true);
      // Rebuild options to reflect new mood hints
      S.options = buildOptions(data.mood);
      renderOptions(S.options);
      break;

    case 'dlgOptions':
      S.options = data.options || [];
      renderOptions(S.options);
      break;
  }
});
