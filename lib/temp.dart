// ignore: non_constant_identifier_names
Map v2_map = {
  'lobby': {
    'key0': {
      'timestamp': int,
      'name': 'roomName0',
      'quote': 'scores',
      'host': 'id0',
      'players': {
        'id0': {
          'token': int,
          'hand': List, // Local
          'rounds': int, // Local
          'points': int, // Local
          'streaks': int, // Local
          'inGame': int, // Local // 0 - Idle (White) | 1 - Playing (Teal) | 2 - Spectating (Orange)
        },
      },
      'lastPlay': {
        'playerTurn': 'id0',
        'cardValue': int,
        'playerTarget': 'id1',
        'gotCards': int, // 0 - Red | -1 - Orange | >0 - Green
        'point': bool,
        'streak': int,
      },
      'scores': {
        'id0': {'points': int, 'streaks': int},
      },
    },
  },
  'users': {
    'id0': {
      'name': 'name0',
      'lastOnline': String,
      'msgs': {
        'enter': bool,
        //'kick': bool,
        'takeCards': List,
        'giveCards': List,
      },
    },
  },
  '|settings': {
    'title': 'Lil Fishy',
    'nameMaxLength': 12,
    'emptyLobbyMsg': 'No rooms',
    'roomLimit': 6,
    'customRoomNames': List,
    'customRoomNamesOdd': 0.01,
    'delay': 250,
    'timestampPeriod': 5,
    'onlineThreshold': 15,
  },
  '|timestamps': {
    'now': int,
    'users': {'id0': int, 'id1': int}
  },
};
