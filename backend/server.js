'use strict';

const express = require('express');
const cors = require('cors');
const { createAuth } = require('./auth');

const app = express();

function readArgument(name, fallback) {
  const index = process.argv.indexOf(name);

  return index >= 0 && process.argv[index + 1]
    ? process.argv[index + 1]
    : fallback;
}

const PORT = Number(readArgument('--port', '8080'));
const ALLOWED_ORIGIN = readArgument(
  '--origin',
  'http://localhost:5555',
);

app.use(cors({
  origin: ALLOWED_ORIGIN,
  methods: [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'OPTIONS',
  ],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
  ],
}));

app.use(express.json({ limit: '1mb' }));

const db = {
  animals: [],
  adopters: [],
  adoptionRequests: [],
  medicalCards: {},

  nextAnimalId: 1,
  nextAdopterId: 1,
  nextRequestId: 1,
};

function seedData() {
  const now = new Date().toISOString();

  db.animals = [];
  db.adopters = [];
  db.adoptionRequests = [];
  db.medicalCards = {};

  const names = [
    'Буся',
    'Луна',
    'Барсик',
    'Мила',
    'Ричи',
    'Снежок',
    'Дымка',
    'Тиша',
    'Муся',
    'Боня',
    'Грей',
    'Кузя',
    'Марта',
    'Том',
    'Соня',
    'Макс',
    'Белка',
    'Тимоша',
    'Лаки',
    'Жужа',
    'Мурка',
    'Бакс',
    'Ириска',
    'Чарли',
  ];

  const breeds = [
    'Метис',
    'Дворняжка',
    'Британская',
    'Шпиц',
    'Лабрадор',
    'Сибирская',
  ];

  db.animals = names.map((name, index) => ({
    id: index + 1,
    name,
    species: index % 3 === 0 ? 'Собака' : 'Кошка',
    breed: breeds[index % breeds.length],
    age: (index % 9) + 1,
    sex: index % 2 === 0 ? 'Самка' : 'Самец',
    status: [
      'Ищет дом',
      'На лечении',
      'На передержке',
    ][index % 3],
    description:
      'Питомец ищет заботливого хозяина и любящий дом.',
    createdAt: now,
    deletedAt: null,
  }));

  const people = [
    ['Анна Смирнова', 'Москва'],
    ['Иван Петров', 'Казань'],
    ['Мария Кузнецова', 'Тула'],
    ['Алексей Волков', 'Самара'],
    ['Елена Соколова', 'Пермь'],
    ['Ольга Иванова', 'Москва'],
    ['Дмитрий Орлов', 'Калуга'],
    ['Екатерина Морозова', 'Тверь'],
    ['Сергей Павлов', 'Воронеж'],
    ['Наталья Белова', 'Казань'],
  ];

  db.adopters = people.map((person, index) => ({
    id: index + 1,
    fullName: person[0],
    city: person[1],
    phone: `+7 900 123-45-${String(index + 10)}`,
    email: `person${index + 1}@example.com`,
    preferredSpecies: index % 2 === 0 ? 'Кошка' : 'Собака',
    createdAt: now,
    deletedAt: null,
  }));

  db.adoptionRequests = [
    {
      id: 1,
      animalId: 1,
      adopterId: 1,
      status: 'На рассмотрении',
      note: 'Есть опыт ухода за животными.',
      createdAt: now,
      deletedAt: null,
    },
    {
      id: 2,
      animalId: 2,
      adopterId: 2,
      status: 'Новая',
      note: '',
      createdAt: now,
      deletedAt: null,
    },
  ];

  db.medicalCards['1'] = {
    animalId: 1,
    passportNumber: 'ВЕТ-0001',
    microchipNumber: '',
    vaccinationNotes: 'Плановая вакцинация.',
    allergies: '',
  };

  db.medicalCards['2'] = {
    animalId: 2,
    passportNumber: 'ВЕТ-0002',
    microchipNumber: '',
    vaccinationNotes: 'Вакцинация проведена.',
    allergies: '',
  };

  db.nextAnimalId = db.animals.length + 1;
  db.nextAdopterId = db.adopters.length + 1;
  db.nextRequestId = db.adoptionRequests.length + 1;
}

function sendValidationError(res, errors, message = 'Ошибка валидации') {
  return res.status(422).json({
    message,
    errors,
  });
}

function validateAnimal(body = {}) {
  const errors = {};

  if (!String(body.name ?? '').trim()) {
    errors.name = 'Укажите кличку питомца.';
  }

  if (
    !['Кошка', 'Собака', 'Другое']
      .includes(String(body.species ?? ''))
  ) {
    errors.species = 'Выберите вид питомца.';
  }

  if (!String(body.breed ?? '').trim()) {
    errors.breed = 'Укажите породу.';
  }

  const age = Number(body.age);

  if (!Number.isInteger(age) || age < 0 || age > 100) {
    errors.age = 'Возраст должен быть от 0 до 100.';
  }

  if (!['Самка', 'Самец'].includes(body.sex)) {
    errors.sex = 'Выберите пол питомца.';
  }

  if (
    ![
      'Ищет дом',
      'На лечении',
      'На передержке',
      'Пристроен',
    ].includes(body.status)
  ) {
    errors.status = 'Укажите корректный статус.';
  }

  return errors;
}

function validateAdopter(body = {}, currentId = null) {
  const errors = {};

  const fullName = String(body.fullName ?? '').trim();
  const city = String(body.city ?? '').trim();
  const phone = String(body.phone ?? '').trim();
  const email = String(body.email ?? '').trim();

  if (!fullName) {
    errors.fullName = 'Укажите ФИО.';
  }

  if (!city) {
    errors.city = 'Укажите город.';
  }

  if (!phone) {
    errors.phone = 'Укажите телефон.';
  }

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    errors.email = 'Укажите корректный email.';
  } else if (
    db.adopters.some(
      item =>
        item.id !== currentId &&
        !item.deletedAt &&
        item.email.toLowerCase() === email.toLowerCase(),
    )
  ) {
    errors.email = 'Этот email уже зарегистрирован.';
  }

  if (
    !['Кошка', 'Собака', 'Не важно']
      .includes(body.preferredSpecies)
  ) {
    errors.preferredSpecies =
      'Выберите предпочтительный вид животного.';
  }

  return errors;
}

function normalizeAnimal(body, id, old = null) {
  return {
    id,
    name: String(body.name).trim(),
    species: String(body.species),
    breed: String(body.breed).trim(),
    age: Number(body.age),
    sex: String(body.sex),
    status: String(body.status),
    description: String(body.description ?? '').trim(),
    createdAt: old?.createdAt ?? new Date().toISOString(),
    deletedAt: old?.deletedAt ?? null,
  };
}

function normalizeAdopter(body, id, old = null) {
  return {
    id,
    fullName: String(body.fullName).trim(),
    city: String(body.city).trim(),
    phone: String(body.phone).trim(),
    email: String(body.email).trim(),
    preferredSpecies: String(body.preferredSpecies),
    createdAt: old?.createdAt ?? new Date().toISOString(),
    deletedAt: old?.deletedAt ?? null,
  };
}

function paginate(rows, query) {
  const page = Math.max(1, Number(query.page) || 1);
  const size = Math.min(
    100,
    Math.max(1, Number(query.size) || 10),
  );

  const start = (page - 1) * size;

  return {
    items: rows.slice(start, start + size),
    page,
    size,
    total: rows.length,
  };
}

function filterRows(collection, query, role) {
  if (
    query.includeDeleted === 'true' &&
    role !== 'admin'
  ) {
    const error = new Error(
      'Просмотр удалённых записей доступен только администратору.',
    );
    error.status = 403;
    throw error;
  }

  let rows = db[collection].filter(
    item => query.includeDeleted === 'true' || !item.deletedAt,
  );

  const search = String(query.search ?? '')
    .trim()
    .toLowerCase();

  if (search) {
    rows = rows.filter(item =>
      Object.values(item)
        .filter(value => typeof value === 'string')
        .join(' ')
        .toLowerCase()
        .includes(search),
    );
  }

  if (collection === 'animals') {
    if (query.species) {
      rows = rows.filter(
        item => item.species === query.species,
      );
    }

    if (query.status) {
      rows = rows.filter(
        item => item.status === query.status,
      );
    }

    if (query.minAge !== undefined) {
      rows = rows.filter(
        item => item.age >= Number(query.minAge),
      );
    }

    if (query.maxAge !== undefined) {
      rows = rows.filter(
        item => item.age <= Number(query.maxAge),
      );
    }
  }

  if (collection === 'adopters' && query.species) {
    rows = rows.filter(
      item => item.preferredSpecies === query.species,
    );
  }

  const allowedSortFields = collection === 'animals'
    ? ['id', 'name', 'species', 'breed', 'age', 'status']
    : ['id', 'fullName', 'city', 'email'];

  const [requestedField, direction] =
    String(query.sort || 'id,asc').split(',');

  const field = allowedSortFields.includes(requestedField)
    ? requestedField
    : 'id';

  const multiplier = direction === 'desc' ? -1 : 1;

  rows.sort((a, b) => {
    const left = a[field];
    const right = b[field];

    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;

    const comparison =
      typeof left === 'number' && typeof right === 'number'
        ? left - right
        : String(left).localeCompare(String(right), 'ru');

    return comparison * multiplier;
  });

  return rows;
}

const auth = createAuth(app);

app.get('/api/__health', (req, res) => {
  return res.json({
    status: 'ok',
    time: new Date().toISOString(),
  });
});

app.use('/api', (req, res, next) => {
  if (
    req.path === '/__health' ||
    req.path.startsWith('/auth/')
  ) {
    return next();
  }

  const failure = Number(req.query.__fail);

  if (failure >= 400 && failure <= 599) {
    return res.status(failure).json({
      message: `Тестовая ошибка сервера: ${failure}`,
    });
  }

  const delay = Math.min(
    10000,
    Math.max(0, Number(req.query.__delay) || 0),
  );

  if (delay > 0) {
    return setTimeout(next, delay);
  }

  return next();
});

app.post('/api/__reset', (req, res) => {
  seedData();

  return res.json({
    message: 'Демонстрационные данные восстановлены.',
  });
});

function registerCrud(
  basePath,
  collection,
  validate,
  normalize,
  nextIdName,
  options = {},
) {
  const readRoles = options.readRoles || [
    'visitor',
    'staff',
    'admin',
  ];

  const writeRoles = ['staff', 'admin'];

  app.get(
    basePath,
    auth.authenticate,
    auth.requireRoles(...readRoles),
    (req, res, next) => {
      try {
        const rows = filterRows(
          collection,
          req.query,
          req.user.role,
        );

        return res.json(paginate(rows, req.query));
      } catch (error) {
        return next(error);
      }
    },
  );

  app.post(
    basePath,
    auth.authenticate,
    auth.requireRoles(...writeRoles),
    (req, res) => {
      const body = req.body || {};
      const errors = validate(body);

      if (Object.keys(errors).length) {
        return sendValidationError(res, errors);
      }

      const id = db[nextIdName]++;

      const duplicateEmail =
        collection === 'adopters' &&
        db.adopters.some(
          item =>
            !item.deletedAt &&
            item.email.toLowerCase() ===
              String(body.email).trim().toLowerCase(),
        );

      if (duplicateEmail) {
        return res.status(409).json({
          message: 'Человек с таким email уже существует.',
        });
      }

      const item = normalize(body, id);
      db[collection].push(item);

      return res.status(201).json(item);
    },
  );

  app.post(
    `${basePath}/bulk-delete`,
    auth.authenticate,
    auth.requireRoles(...writeRoles),
    (req, res) => {
      const ids = Array.isArray(req.body?.ids)
        ? req.body.ids.map(Number)
        : [];

      if (
        !ids.length ||
        ids.some(id => !Number.isInteger(id))
      ) {
        return sendValidationError(res, {
          ids: 'Передайте массив идентификаторов.',
        });
      }

      let deleted = 0;

      for (const item of db[collection]) {
        if (ids.includes(item.id) && !item.deletedAt) {
          item.deletedAt = new Date().toISOString();
          deleted++;
        }
      }

      return res.json({ deleted });
    },
  );

  app.post(
    `${basePath}/:id/restore`,
    auth.authenticate,
    auth.requireRoles('admin'),
    (req, res) => {
      const id = Number(req.params.id);
      const item = db[collection].find(
        row => row.id === id,
      );

      if (!item) {
        return res.status(404).json({
          message: 'Запись не найдена.',
        });
      }

      item.deletedAt = null;

      return res.json(item);
    },
  );

  app.get(
    `${basePath}/:id`,
    auth.authenticate,
    auth.requireRoles(...readRoles),
    (req, res) => {
      const id = Number(req.params.id);

      if (
        req.query.includeDeleted === 'true' &&
        req.user.role !== 'admin'
      ) {
        return res.status(403).json({
          message: 'Недостаточно прав.',
        });
      }

      const item = db[collection].find(
        row =>
          row.id === id &&
          (
            req.query.includeDeleted === 'true' ||
            !row.deletedAt
          ),
      );

      if (!item) {
        return res.status(404).json({
          message: 'Запись не найдена.',
        });
      }

      return res.json(item);
    },
  );

  app.put(
    `${basePath}/:id`,
    auth.authenticate,
    auth.requireRoles(...writeRoles),
    (req, res) => {
      const id = Number(req.params.id);

      const index = db[collection].findIndex(
        item => item.id === id && !item.deletedAt,
      );

      if (index < 0) {
        return res.status(404).json({
          message: 'Запись не найдена.',
        });
      }

      const body = req.body || {};
      const errors = validate(body, id);

      if (Object.keys(errors).length) {
        return sendValidationError(res, errors);
      }

      const updated = normalize(
        body,
        id,
        db[collection][index],
      );

      db[collection][index] = updated;

      return res.json(updated);
    },
  );

  app.delete(
    `${basePath}/:id`,
    auth.authenticate,
    auth.requireRoles(...writeRoles),
    (req, res) => {
      const id = Number(req.params.id);
      const index = db[collection].findIndex(
        item => item.id === id,
      );

      if (index < 0) {
        return res.status(404).json({
          message: 'Запись не найдена.',
        });
      }

      if (req.query.hard === 'true') {
        if (req.user.role !== 'admin') {
          return res.status(403).json({
            message:
              'Физическое удаление доступно только администратору.',
          });
        }

        db[collection].splice(index, 1);

        if (collection === 'animals') {
          delete db.medicalCards[String(id)];

          db.adoptionRequests =
            db.adoptionRequests.filter(
              item => item.animalId !== id,
            );
        } else {
          db.adoptionRequests =
            db.adoptionRequests.filter(
              item => item.adopterId !== id,
            );
        }
      } else {
        db[collection][index].deletedAt =
          new Date().toISOString();
      }

      return res.status(204).end();
    },
  );
}

registerCrud(
  '/api/animals',
  'animals',
  validateAnimal,
  normalizeAnimal,
  'nextAnimalId',
  {
    readRoles: ['visitor', 'staff', 'admin'],
  },
);

registerCrud(
  '/api/adopters',
  'adopters',
  validateAdopter,
  normalizeAdopter,
  'nextAdopterId',
  {
    readRoles: ['staff', 'admin'],
  },
);

app.get(
  '/api/adoption-requests',
  auth.authenticate,
  auth.requireRoles('staff', 'admin'),
  (req, res) => {
    let rows = db.adoptionRequests.filter(
      item => !item.deletedAt,
    );

    if (req.query.animalId) {
      rows = rows.filter(
        item => item.animalId === Number(req.query.animalId),
      );
    }

    if (req.query.adopterId) {
      rows = rows.filter(
        item => item.adopterId === Number(req.query.adopterId),
      );
    }

    return res.json(rows);
  },
);

app.post(
  '/api/adoption-requests',
  auth.authenticate,
  auth.requireRoles('staff', 'admin'),
  (req, res) => {
    const animalId = Number(req.body?.animalId);
    const adopterId = Number(req.body?.adopterId);

    const errors = {};

    if (
      !db.animals.some(
        item => item.id === animalId && !item.deletedAt,
      )
    ) {
      errors.animalId = 'Питомец не найден.';
    }

    if (
      !db.adopters.some(
        item => item.id === adopterId && !item.deletedAt,
      )
    ) {
      errors.adopterId = 'Кандидат не найден.';
    }

    if (Object.keys(errors).length) {
      return sendValidationError(res, errors);
    }

    const conflict = db.adoptionRequests.some(
      item =>
        !item.deletedAt &&
        item.animalId === animalId &&
        item.adopterId === adopterId &&
        item.status !== 'Отклонена',
    );

    if (conflict) {
      return res.status(409).json({
        message: 'Для этой пары уже существует активная заявка.',
      });
    }

    const item = {
      id: db.nextRequestId++,
      animalId,
      adopterId,
      status: 'Новая',
      note: String(req.body?.note ?? ''),
      createdAt: new Date().toISOString(),
      deletedAt: null,
    };

    db.adoptionRequests.push(item);

    return res.status(201).json(item);
  },
);

app.put(
  '/api/adoption-requests/:id',
  auth.authenticate,
  auth.requireRoles('staff', 'admin'),
  (req, res) => {
    const id = Number(req.params.id);

    const item = db.adoptionRequests.find(
      row => row.id === id && !row.deletedAt,
    );

    if (!item) {
      return res.status(404).json({
        message: 'Заявка не найдена.',
      });
    }

    const statuses = [
      'Новая',
      'На рассмотрении',
      'Одобрена',
      'Отклонена',
    ];

    if (!statuses.includes(req.body?.status)) {
      return sendValidationError(res, {
        status: 'Укажите корректный статус заявки.',
      });
    }

    if (
      req.body.status === 'Одобрена' &&
      db.adoptionRequests.some(
        row =>
          row.id !== id &&
          row.animalId === item.animalId &&
          row.status === 'Одобрена' &&
          !row.deletedAt,
      )
    ) {
      return res.status(409).json({
        message:
          'Для этого питомца уже одобрена другая заявка.',
      });
    }

    item.status = req.body.status;

    if (req.body.note != null) {
      item.note = String(req.body.note);
    }

    return res.json(item);
  },
);

app.delete(
  '/api/adoption-requests/:id',
  auth.authenticate,
  auth.requireRoles('staff', 'admin'),
  (req, res) => {
    const id = Number(req.params.id);

    const item = db.adoptionRequests.find(
      row => row.id === id && !row.deletedAt,
    );

    if (!item) {
      return res.status(404).json({
        message: 'Заявка не найдена.',
      });
    }

    item.deletedAt = new Date().toISOString();

    return res.status(204).end();
  },
);

app.get(
  '/api/medical-cards/:animalId',
  auth.authenticate,
  auth.requireRoles('staff', 'admin'),
  (req, res) => {
    const animalId = Number(req.params.animalId);

    const animal = db.animals.find(
      item => item.id === animalId && !item.deletedAt,
    );

    if (!animal) {
      return res.status(404).json({
        message: 'Питомец не найден.',
      });
    }

    const card = db.medicalCards[String(animalId)] ?? {
      animalId,
      passportNumber: '',
      microchipNumber: '',
      vaccinationNotes: '',
      allergies: '',
    };

    return res.json(card);
  },
);

app.put(
  '/api/medical-cards/:animalId',
  auth.authenticate,
  auth.requireRoles('staff', 'admin'),
  (req, res) => {
    const animalId = Number(req.params.animalId);

    const animal = db.animals.find(
      item => item.id === animalId && !item.deletedAt,
    );

    if (!animal) {
      return res.status(404).json({
        message: 'Питомец не найден.',
      });
    }

    const card = {
      animalId,
      passportNumber: String(
        req.body?.passportNumber ?? '',
      ),
      microchipNumber: String(
        req.body?.microchipNumber ?? '',
      ),
      vaccinationNotes: String(
        req.body?.vaccinationNotes ?? '',
      ),
      allergies: String(req.body?.allergies ?? ''),
    };

    db.medicalCards[String(animalId)] = card;

    return res.json(card);
  },
);

app.delete(
  '/api/medical-cards/:animalId',
  auth.authenticate,
  auth.requireRoles('admin'),
  (req, res) => {
    const animalId = Number(req.params.animalId);

    if (!db.medicalCards[String(animalId)]) {
      return res.status(404).json({
        message: 'Медицинская карточка не найдена.',
      });
    }

    delete db.medicalCards[String(animalId)];

    return res.status(204).end();
  },
);

app.use('/api', (req, res) => {
  return res.status(404).json({
    message: 'Маршрут API не найден.',
  });
});

app.use((error, req, res, next) => {
  console.error('[API error]', error.message);

  if (res.headersSent) {
    return next(error);
  }

  const status = error.status || 500;

  return res.status(status).json({
    message:
      status === 400
        ? 'Некорректный JSON в запросе.'
        : status === 403
          ? error.message
          : 'Внутренняя ошибка сервера.',
  });
});

seedData();

app.listen(PORT, () => {
  console.log(
    `API «Лапки и дом»: http://localhost:${PORT}/api`,
  );

  console.log(`Разрешённый источник: ${ALLOWED_ORIGIN}`);

  console.log('Проверка сервера: /api/__health');

  console.log('Тестовые роли: visitor, staff, admin');
});