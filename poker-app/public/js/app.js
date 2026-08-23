(() => {
  const SUIT_SYMBOL = { s: '♠', h: '♥', d: '♦', c: '♣' };
  const RED_SUITS = new Set(['h', 'd']);

  const state = {
    account: null,
    socket: null,
    currentTableId: null,
    lastTableState: null,
    catalog: [],
    pendingJoin: null, // { tableId, min, max }
  };

  const $ = (sel) => document.querySelector(sel);
  const show = (el) => el.classList.remove('hidden');
  const hide = (el) => el.classList.add('hidden');

  // ---------- Auth ----------
  let authMode = 'login';
  $('#auth-toggle-link').addEventListener('click', (e) => {
    e.preventDefault();
    authMode = authMode === 'login' ? 'register' : 'login';
    $('#auth-submit').textContent = authMode === 'login' ? 'Log in' : 'Create account';
    $('#auth-toggle-text').textContent = authMode === 'login' ? 'New here?' : 'Already playing?';
    $('#auth-toggle-link').textContent = authMode === 'login' ? 'Create an account' : 'Log in';
    $('#auth-error').textContent = '';
  });

  $('#auth-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = $('#auth-username').value.trim();
    const password = $('#auth-password').value;
    $('#auth-error').textContent = '';
    try {
      const res = await fetch(`/api/${authMode === 'login' ? 'login' : 'register'}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Failed');
      state.account = data.user;
      enterApp();
    } catch (err) {
      $('#auth-error').textContent = err.message;
    }
  });

  $('#logout-btn').addEventListener('click', async () => {
    await fetch('/api/logout', { method: 'POST' });
    if (state.socket) state.socket.disconnect();
    location.reload();
  });

  async function tryResumeSession() {
    try {
      const res = await fetch('/api/me');
      if (!res.ok) return;
      const data = await res.json();
      state.account = data.user;
      enterApp();
    } catch (_) {}
  }

  function enterApp() {
    hide($('#auth-screen'));
    show($('#lobby-screen'));
    updateAccountBar();
    connectSocket();
  }

  function updateAccountBar() {
    if (!state.account) return;
    $('#account-name').textContent = state.account.username;
    $('#account-balance').textContent = state.account.balance;
    $('#account-balance-2').textContent = state.account.balance;
  }

  // ---------- Socket ----------
  function connectSocket() {
    state.socket = io();
    const socket = state.socket;

    socket.on('account:state', (account) => {
      state.account = account;
      updateAccountBar();
      renderShop();
    });

    socket.on('lobby:update', (tables) => renderLobby(tables));

    socket.on('table:state', (tableState) => {
      state.lastTableState = tableState;
      renderTable(tableState);
    });

    socket.on('connect', () => {
      socket.emit('lobby:list', (res) => renderLobby(res.tables));
    });

    fetch('/api/shop').then((r) => r.json()).then((d) => {
      state.catalog = d.catalog;
      renderShop();
    });
  }

  // ---------- Lobby ----------
  function renderLobby(tables) {
    const list = $('#table-list');
    list.innerHTML = '';
    for (const t of tables) {
      const card = document.createElement('div');
      card.className = 'table-card';
      card.innerHTML = `
        <h3>${escapeHtml(t.name)}</h3>
        <div class="stakes">${t.smallBlind}/${t.bigBlind} chips</div>
        <div class="meta">${t.players}/${t.maxSeats} seated &middot; ${t.phase}</div>
        <button>Join Table</button>
      `;
      card.querySelector('button').addEventListener('click', () => openBuyIn(t));
      list.appendChild(card);
    }
  }

  function openBuyIn(t) {
    const min = t.smallBlind * 2 * 20; // rough default, server clamps exactly
    const max = t.bigBlind * 200;
    state.pendingJoin = { tableId: t.id };
    const slider = $('#buyin-amount');
    slider.min = min;
    slider.max = max;
    slider.value = max;
    $('#buyin-amount-label').textContent = `${max} chips`;
    $('#buyin-range-label').textContent = `Buy in between ${min} and ${max} chips`;
    show($('#buyin-modal'));
  }

  $('#buyin-amount').addEventListener('input', (e) => {
    $('#buyin-amount-label').textContent = `${e.target.value} chips`;
  });
  $('#cancel-buyin').addEventListener('click', () => hide($('#buyin-modal')));
  $('#confirm-buyin').addEventListener('click', () => {
    if (!state.pendingJoin) return;
    const buyIn = parseInt($('#buyin-amount').value, 10);
    state.socket.emit(
      'table:join',
      { tableId: state.pendingJoin.tableId, buyIn },
      (res) => {
        if (!res.ok) {
          alert(res.error);
          return;
        }
        hide($('#buyin-modal'));
        state.currentTableId = state.pendingJoin.tableId;
        hide($('#lobby-screen'));
        show($('#table-screen'));
      }
    );
  });

  $('#leave-table-btn').addEventListener('click', () => {
    state.socket.emit('table:leave', {}, () => {
      hide($('#table-screen'));
      show($('#lobby-screen'));
      state.currentTableId = null;
      state.socket.emit('lobby:list', (res) => renderLobby(res.tables));
    });
  });

  // ---------- Table rendering ----------
  function cardEl(card, faceDown) {
    const el = document.createElement('div');
    if (faceDown || card === 'back') {
      el.className = 'card back';
      const equippedBack = state.account && state.account.equipped && state.account.equipped.cardBack;
      if (equippedBack) el.classList.add(`deck-${equippedBack}`);
      return el;
    }
    const red = RED_SUITS.has(card.suit);
    el.className = `card ${red ? 'red' : 'black'}`;
    el.textContent = `${card.rank}${SUIT_SYMBOL[card.suit]}`;
    return el;
  }

  function renderTable(t) {
    $('#table-title').textContent = `${t.name} — ${t.smallBlind}/${t.bigBlind}`;
    const felt = $('#felt');
    felt.className = 'felt';
    const equippedFelt = state.account && state.account.equipped && state.account.equipped.tableFelt;
    if (equippedFelt) felt.classList.add(`theme-${equippedFelt}`);

    const community = $('#community-cards');
    community.innerHTML = '';
    t.communityCards.forEach((c) => community.appendChild(cardEl(c)));

    const potTotal = t.phase === 'showdown'
      ? (t.pots || []).reduce((s, p) => s + p.amount, 0)
      : t.totalPot;
    $('#pot-display').textContent = potTotal ? `Pot: ${potTotal}` : '';

    const seatsEl = $('#seats');
    seatsEl.dataset.seats = t.maxSeats;
    seatsEl.innerHTML = '';
    const mySeatIndex = t.seats.findIndex(
      (s) => s && state.account && s.userId === state.account.id
    );

    for (let i = 0; i < t.maxSeats; i++) {
      const seat = t.seats[i];
      const wrap = document.createElement('div');
      wrap.className = 'seat';
      if (seat && i === t.actingIndex) wrap.classList.add('acting');
      if (seat && seat.folded) wrap.classList.add('folded');

      if (!seat) {
        wrap.innerHTML = `<div class="empty-seat">Empty seat<br/>Tap to sit</div>`;
        wrap.querySelector('.empty-seat').addEventListener('click', () => {
          state.socket.emit('table:join', { tableId: t.id, seatIndex: i }, (res) => {
            if (!res.ok) alert(res.error);
          });
        });
      } else {
        const box = document.createElement('div');
        box.className = 'seat-box';
        box.innerHTML = `
          <div class="name">${escapeHtml(seat.name)}${i === t.buttonIndex ? ' 🔘' : ''}</div>
          <div class="stack">${seat.stack} chips</div>
          ${seat.bet ? `<div class="bet-badge">Bet ${seat.bet}</div>` : ''}
          ${seat.lastAction ? `<div class="last-action">${seat.lastAction}</div>` : ''}
        `;
        const holeWrap = document.createElement('div');
        holeWrap.className = 'hole-cards';
        seat.holeCards.forEach((c) => holeWrap.appendChild(cardEl(c)));
        box.appendChild(holeWrap);
        wrap.appendChild(box);
      }
      seatsEl.appendChild(wrap);
    }

    $('#hand-log').textContent = (t.log || []).join(' · ');

    const mySeat = mySeatIndex >= 0 ? t.seats[mySeatIndex] : null;
    const myTurn = mySeat && t.actingIndex === mySeatIndex && !mySeat.folded && !mySeat.allIn;
    const actionBar = $('#action-bar');
    if (myTurn) {
      show(actionBar);
      const toCall = t.currentBet - mySeat.bet;
      $('#act-check').classList.toggle('hidden', toCall > 0);
      $('#act-call').classList.toggle('hidden', toCall <= 0);
      $('#act-call').textContent = `Call ${toCall}`;
      const slider = $('#raise-amount');
      const minRaise = Math.min(t.currentBet + t.minRaise, mySeat.stack + mySeat.bet);
      slider.min = minRaise;
      slider.max = mySeat.stack + mySeat.bet;
      slider.value = minRaise;
      $('#raise-amount-label').textContent = minRaise;
      $('#act-raise').textContent = t.currentBet === 0 ? 'Bet' : 'Raise to';
    } else {
      hide(actionBar);
    }
  }

  $('#raise-amount').addEventListener('input', (e) => {
    $('#raise-amount-label').textContent = e.target.value;
  });

  function act(action, amount) {
    if (!state.currentTableId) return;
    state.socket.emit(
      'table:action',
      { tableId: state.currentTableId, action, amount },
      (res) => {
        if (!res.ok) alert(res.error);
      }
    );
  }
  $('#act-fold').addEventListener('click', () => act('fold'));
  $('#act-check').addEventListener('click', () => act('check'));
  $('#act-call').addEventListener('click', () => act('call'));
  $('#act-allin').addEventListener('click', () => act('allin'));
  $('#act-raise').addEventListener('click', () => {
    const amount = parseInt($('#raise-amount').value, 10);
    act(state.lastTableState.currentBet === 0 ? 'bet' : 'raise', amount);
  });

  // ---------- Shop ----------
  $('#open-shop').addEventListener('click', () => show($('#shop-modal')));
  $('#close-shop').addEventListener('click', () => hide($('#shop-modal')));

  function renderShop() {
    if (!state.account || !state.catalog.length) return;
    const container = $('#shop-items');
    container.innerHTML = '';
    for (const item of state.catalog) {
      const owned = state.account.owned.includes(item.id);
      const equipped = state.account.equipped[item.type] === item.id;
      const div = document.createElement('div');
      div.className = 'shop-item';
      const swatchColor = swatchFor(item);
      div.innerHTML = `
        ${swatchColor ? `<div class="swatch" style="background:${swatchColor}"></div>` : ''}
        <div class="item-name">${escapeHtml(item.name)}</div>
        <div class="item-price">${item.price === 0 ? 'Free' : `🪙 ${item.price}`}</div>
        <button class="${equipped ? 'equipped' : owned ? 'owned' : ''}">
          ${equipped ? 'Equipped' : owned ? 'Equip' : 'Buy'}
        </button>
      `;
      div.querySelector('button').addEventListener('click', () => {
        if (equipped) return;
        const ev = owned ? 'shop:equip' : 'shop:buy';
        state.socket.emit(ev, { cosmeticId: item.id }, (res) => {
          if (!res.ok) alert(res.error);
        });
      });
      container.appendChild(div);
    }
  }

  function swatchFor(item) {
    const map = {
      'felt-green': '#0b5c3a', 'felt-midnight': '#17245c', 'felt-crimson': '#6c1622', 'felt-charcoal': '#2b2f33',
      'avatar-1': '#e07a3f', 'avatar-2': '#2c78c9', 'avatar-3': '#8a4fd6',
      'back-classic': '#7a1f1f', 'back-royal': '#1c3f9c', 'back-emerald': '#1f7a4f', 'back-gold': '#b8912e',
    };
    return map[item.id];
  }

  function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, (c) => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
    }[c]));
  }

  tryResumeSession();
})();
