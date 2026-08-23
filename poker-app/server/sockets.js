const db = require('./db');

function registerSocketHandlers(io, gameManager) {
  function broadcastTable(table) {
    const room = io.sockets.adapter.rooms.get(table.id);
    if (!room) return;
    for (const socketId of room) {
      const sock = io.sockets.sockets.get(socketId);
      if (!sock || !sock.user) continue;
      const seatIndex = table.seats.findIndex((s) => s && s.userId === sock.user.id);
      sock.emit('table:state', table.publicState(seatIndex));
    }
  }

  function withTableBroadcast(tableId, fn) {
    const table = gameManager.getTable(tableId);
    if (!table) return;
    fn(table);
    broadcastTable(table);
    // A settled hand schedules the next deal a few seconds later; refresh then too.
    setTimeout(() => broadcastTable(table), 3200);
  }

  io.on('connection', (socket) => {
    const userId = socket.request.session && socket.request.session.userId;
    if (!userId) {
      socket.emit('auth:required');
      socket.disconnect(true);
      return;
    }
    const account = db.getUser(userId);
    if (!account) {
      socket.disconnect(true);
      return;
    }
    socket.user = { id: account.id, username: account.username };
    socket.join('lobby');
    socket.emit('account:state', account);

    socket.on('lobby:list', (cb) => {
      cb && cb({ tables: gameManager.listTables() });
    });

    socket.on('table:join', ({ tableId, seatIndex, buyIn }, cb) => {
      try {
        const account = db.getUser(socket.user.id);
        const { seatIndex: assigned, table } = gameManager.sitDown(
          tableId,
          { id: socket.user.id, username: socket.user.username },
          seatIndex,
          buyIn
        );
        socket.currentTableId = tableId;
        socket.join(tableId);
        cb && cb({ ok: true, seatIndex: assigned, buyInRange: gameManager.buyInRange(table) });
        broadcastTable(table);
        io.to('lobby').emit('lobby:update', gameManager.listTables());
      } catch (err) {
        cb && cb({ ok: false, error: err.message });
      }
    });

    socket.on('table:leave', (_data, cb) => {
      if (socket.currentTableId) {
        gameManager.standUp(socket.currentTableId, socket.user.id);
        const table = gameManager.getTable(socket.currentTableId);
        if (table) broadcastTable(table);
        socket.leave(socket.currentTableId);
        socket.emit('account:state', db.getUser(socket.user.id));
        socket.currentTableId = null;
        io.to('lobby').emit('lobby:update', gameManager.listTables());
      }
      cb && cb({ ok: true });
    });

    socket.on('table:action', ({ tableId, action, amount }, cb) => {
      try {
        withTableBroadcast(tableId, (table) => {
          gameManager.handleAction(tableId, socket.user.id, action, amount);
        });
        cb && cb({ ok: true });
      } catch (err) {
        cb && cb({ ok: false, error: err.message });
      }
    });

    socket.on('shop:buy', ({ cosmeticId }, cb) => {
      try {
        const user = db.purchaseCosmetic(socket.user.id, cosmeticId);
        socket.emit('account:state', user);
        cb && cb({ ok: true, user });
      } catch (err) {
        cb && cb({ ok: false, error: err.message });
      }
    });

    socket.on('shop:equip', ({ cosmeticId }, cb) => {
      try {
        const user = db.equipCosmetic(socket.user.id, cosmeticId);
        socket.emit('account:state', user);
        cb && cb({ ok: true, user });
      } catch (err) {
        cb && cb({ ok: false, error: err.message });
      }
    });

    socket.on('disconnect', () => {
      if (socket.currentTableId) {
        gameManager.standUp(socket.currentTableId, socket.user.id);
        const table = gameManager.getTable(socket.currentTableId);
        if (table) broadcastTable(table);
        io.to('lobby').emit('lobby:update', gameManager.listTables());
      }
    });
  });
}

module.exports = { registerSocketHandlers };
