'use strict';

const express = require('express');
const cors = require('cors');

const app = express();

function readArgument(name, defaultValue) {
  const index = process.argv.indexOf(name);
  return index >= 0 && process.argv[index + 1]
    ? process.argv[index + 1]
    : defaultValue;
}

const PORT = Number(readArgument('--port', '8080'));
const ALLOWED_ORIGIN = readArgument(
  '--origin',
  'http://localhost:5555',
);

app.use(cors({
  origin: ALLOWED_ORIGIN,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
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

  const animalNames = [
    'Буся', 'Луна', 'Барсик', 'Мила',
    'Ричи', 'Снежок', 'Дымка', 'Тиша',
  ];

  const breeds = [
    'Метис', 'Шпиц', 'Британская', 'Дворняжка',
  ];

  db.animals = Array.from({ length: 24 }, (_, index) => ({
    id: index + 1,
    name: animalNames[index % animalNames.length]
      + (index >= 8 ? ` ${index + 1}` : ''),
    species: index % 3 === 0 ? 'Собака' : 'Кошка',
    breed: breeds[index % breeds.length],
    age: (index % 9) + 1,
    sex: index % 2 === 0 ? 'Самка' : 'Самец',
    status: ['Ищет дом', 'На лечении', 'На передержке'][index % 3],
    description:
      'Дружелюбный питомец, которому нужен заботливый дом.',
    createdAt: now,
    deletedAt: null,
  }));

  const names = [
    'Анна Смирнова',
    'Иван Петров',
    'Мария Кузнецова',
    'Алексей Волков',
    'Елена Соколова',
  ];

  const cities = ['Москва', 'Казань', 'Тула', 'Самара', 'Пермь'];

  db.adopters = Array.from({ length: 10 }, (_, index) => ({
    id: index + 1,
    fullName: names[index % names.length]
      + (index >= 5 ? ` ${index + 1}` : ''),
    city: cities[index % cities.length],
    phone: `+7 900 123-45-${String(index + 10)}`,
    email: `user${index + 1}@example.com`,
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
      createdAt: '2026-10-02T00:00:00.000Z',
      note: 'Есть опыт ухода за кошками.',
      deletedAt: null,
    },
    {
      id: 2,
      animalId: 1,
      adopterId: 2,
      status: 'Новая',
      createdAt: '2026-10-06T00:00:00.000Z',
      note: '',
      deletedAt: null,
    },
    {
      id: 3,
      animalId: 4,
      adopterId: 2,
      status: 'Одобрена',
      createdAt: '2026-10-08T00:00:00.000Z',
      note: 'Условия для содержания проверены.',
      deletedAt: null,
    },
    {
      id: 4,
      animalId: 5,
      adopterId: 4,
      status: 'Отклонена',
      createdAt: '2026-10-12T00:00:00.000Z',
      note: '',
      deletedAt: null,
    },
  ];

  db.medicalCards = {
    1: {
      animalId: 1,
      passportNumber: 'ВЕТ-0001',
      microchipNumber: '643098100001001',
      vaccinationNotes: 'Комплексная вакцинация, 2026 г.',
      allergies: '',
    },
    2: {
      animalId: 2,
      passportNumber: 'ВЕТ-0002',
      microchipNumber: '643098100001002',
      vaccinationNotes: 'Плановая вакцинация завершена.',
      allergies: 'Нет известных аллергий',
    },
  };

  db.nextAnimalId = 25;
  db.nextAdopterId = 11;
  db.nextRequestId = 5;
}

function validateAnimal(body) {
  const errors = {};

  if (!String(body.name ?? '').trim()) {
    errors.name = 'Укажите кличку питомца';
  }

  if (!['Кошка', 'Собака', 'Другое'].includes(body.species)) {
    errors.species = 'Выберите вид питомца';
  }

  if (!String(body.breed ?? '').trim()) {
    errors.breed = 'Укажите породу';
  }

  const age = Number(body.age);

  if (!Number.isInteger(age) || age < 0 || age > 100) {
    errors.age = 'Возраст должен быть от 0 до 100';
  }

  if (!['Самка', 'Самец'].includes(body.sex)) {
    errors.sex = 'Выберите пол';
  }

  if (
    !['Ищет дом', 'На лечении', 'На передержке', 'Пристроен']
      .includes(body.status)
  ) {
    errors.status = 'Укажите корректный статус';
  }

  return errors;
}

function validateAdopter(body, currentId = null) {
  const errors = {};

  const fullName = String(body.fullName ?? '').trim();
  const city = String(body.city ?? '').trim();
  const phone = String(body.phone ?? '').trim();
  const email = String(body.email ?? '').trim();

  if (!fullName) errors.fullName = 'Укажите ФИО';
  if (!city) errors.city = 'Укажите город';
  if (!phone) errors.phone = 'Укажите телефон';

  if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(email)) {
    errors.email = 'Укажите корректную электронную почту';
  } else if (
    db.adopters.some(
      item =>
        item.id !== currentId &&
        !item.deletedAt &&
        item.email.toLowerCase() === email.toLowerCase(),
    )
  ) {
    errors.email = 'Человек с такой почтой уже существует';
  }

  if (
    !['Кошка', 'Собака', 'Не важно']
      .includes(body.preferredSpecies)
  ) {
    errors.preferredSpecies = 'Укажите предпочтительный вид';
  }

  return errors;
}

function paginate(rows, query) {
  const page = Math.max(1, Number(query.page) || 1);
  const size = Math.min(100, Math.max(1, Number(query.size) || 10));
  const start = (page - 1) * size;

  return {
    items: rows.slice(start, start + size),
    page,
    size,
    total: rows.length,
  };
}

function filterRows(collection, query) {
  let rows = db[collection].filter(
    item => query.includeDeleted === 'true' || !item.deletedAt,
  );

  const search = String(query.search ?? '').trim().toLowerCase();

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
      rows = rows.filter(item => item.species === query.species);
    }

    if (query.status) {
      rows = rows.filter(item => item.status === query.status);
    }

    if (query.minAge !== undefined) {
      rows = rows.filter(item => item.age >= Number(query.minAge));
    }

    if (query.maxAge !== undefined) {
      rows = rows.filter(item => item.age <= Number(query.maxAge));
    }
  }

  if (collection === 'adopters' && query.species) {
    rows = rows.filter(
      item => item.preferredSpecies === query.species,
    );
  }

  const [field, direction] =
    String(query.sort || 'id,asc').split(',');

  const multiplier = direction === 'desc' ? -1 : 1;

  rows.sort((a, b) => {
    const left = a[field];
    const right = b[field];

    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;

    const compare =
      typeof left === 'number' && typeof right === 'number'
        ? left - right
        : String(left).localeCompare(String(right), 'ru');

    return compare * multiplier;
  });

  return rows;
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

function sendValidationError(res, errors) {
  res.status(422).json({
    message: 'Ошибка валидации',
    errors,
  });
}

function registerCrud(basePath, collection, validate, normalize, nextIdName) {
  app.get(basePath, (req, res) => {
    const rows = filterRows(collection, req.query);
    res.json(paginate(rows, req.query));
  });

  app.post(basePath, (req, res) => {
    const errors = validate(req.body);

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
            String(req.body.email).trim().toLowerCase(),
      );

    if (duplicateEmail) {
      return res.status(409).json({
        message: 'Человек с такой почтой уже существует',
      });
    }

    const item = normalize(req.body, id);
    db[collection].push(item);

    res.status(201).json(item);
  });

  app.post(`${basePath}/bulk-delete`, (req, res) => {
    const ids = Array.isArray(req.body.ids)
      ? req.body.ids.map(Number)
      : [];

    if (!ids.length || ids.some(id => !Number.isInteger(id))) {
      return sendValidationError(res, {
        ids: 'Передайте массив идентификаторов',
      });
    }

    let deleted = 0;

    for (const item of db[collection]) {
      if (ids.includes(item.id) && !item.deletedAt) {
        item.deletedAt = new Date().toISOString();
        deleted++;
      }
    }

    res.json({ deleted });
  });

  app.post(`${basePath}/:id/restore`, (req, res) => {
    const id = Number(req.params.id);
    const item = db[collection].find(row => row.id === id);

    if (!item) {
      return res.status(404).json({
        message: 'Запись не найдена',
      });
    }

    item.deletedAt = null;
    res.json(item);
  });

  app.get(`${basePath}/:id`, (req, res) => {
    const id = Number(req.params.id);

    const item = db[collection].find(
      row =>
        row.id === id &&
        (req.query.includeDeleted === 'true' || !row.deletedAt),
    );

    if (!item) {
      return res.status(404).json({
        message: 'Запись не найдена',
      });
    }

    res.json(item);
  });

  app.put(`${basePath}/:id`, (req, res) => {
    const id = Number(req.params.id);
    const index = db[collection].findIndex(
      item => item.id === id && !item.deletedAt,
    );

    if (index < 0) {
      return res.status(404).json({
        message: 'Запись не найдена',
      });
    }

    const errors = validate(req.body, id);

    if (Object.keys(errors).length) {
      return sendValidationError(res, errors);
    }

    if (
      collection === 'adopters' &&
      db.adopters.some(
        item =>
          item.id !== id &&
          !item.deletedAt &&
          item.email.toLowerCase() ===
            String(req.body.email).trim().toLowerCase(),
      )
    ) {
      return res.status(409).json({
        message: 'Человек с такой почтой уже существует',
      });
    }

    const updated = normalize(
      req.body,
      id,
      db[collection][index],
    );

    db[collection][index] = updated;
    res.json(updated);
  });

  app.delete(`${basePath}/:id`, (req, res) => {
    const id = Number(req.params.id);
    const index = db[collection].findIndex(
      item => item.id === id,
    );

    if (index < 0) {
      return res.status(404).json({
        message: 'Запись не найдена',
      });
    }

    if (req.query.hard === 'true') {
      db[collection].splice(index, 1);

      if (collection === 'animals') {
        delete db.medicalCards[String(id)];

        db.adoptionRequests = db.adoptionRequests.filter(
          item => item.animalId !== id,
        );
      } else {
        db.adoptionRequests = db.adoptionRequests.filter(
          item => item.adopterId !== id,
        );
      }
    } else {
      db[collection][index].deletedAt = new Date().toISOString();
    }

    res.status(204).end();
  });
}

app.use('/api', (req, res, next) => {
  if (req.path === '/__health') {
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

  next();
});

registerCrud(
  '/api/animals',
  'animals',
  validateAnimal,
  normalizeAnimal,
  'nextAnimalId',
);

registerCrud(
  '/api/adopters',
  'adopters',
  validateAdopter,
  normalizeAdopter,
  'nextAdopterId',
);

app.get('/api/adoption-requests', (req, res) => {
  const rows = db.adoptionRequests.filter(
    item =>
      !item.deletedAt &&
      (!req.query.animalId ||
        item.animalId === Number(req.query.animalId)) &&
      (!req.query.adopterId ||
        item.adopterId === Number(req.query.adopterId)),
  );

  res.json(rows);
});

app.post('/api/adoption-requests', (req, res) => {
  const animalId = Number(req.body.animalId);
  const adopterId = Number(req.body.adopterId);
  const errors = {};

  if (!db.animals.some(
    item => item.id === animalId && !item.deletedAt,
  )) {
    errors.animalId = 'Питомец не найден';
  }

  if (!db.adopters.some(
    item => item.id === adopterId && !item.deletedAt,
  )) {
    errors.adopterId = 'Кандидат не найден';
  }

  if (Object.keys(errors).length) {
    return sendValidationError(res, errors);
  }

  const duplicate = db.adoptionRequests.some(
    item =>
      !item.deletedAt &&
      item.animalId === animalId &&
      item.adopterId === adopterId &&
      item.status !== 'Отклонена',
  );

  if (duplicate) {
    return res.status(409).json({
      message: 'Для этой пары уже существует активная заявка',
    });
  }

  const item = {
    id: db.nextRequestId++,
    animalId,
    adopterId,
    status: 'Новая',
    note: String(req.body.note ?? ''),
    createdAt: new Date().toISOString(),
    deletedAt: null,
  };

  db.adoptionRequests.push(item);
  res.status(201).json(item);
});

app.put('/api/adoption-requests/:id', (req, res) => {
  const id = Number(req.params.id);

  const item = db.adoptionRequests.find(
    row => row.id === id && !row.deletedAt,
  );

  if (!item) {
    return res.status(404).json({
      message: 'Заявка не найдена',
    });
  }

  const statuses = [
    'Новая',
    'На рассмотрении',
    'Одобрена',
    'Отклонена',
  ];

  if (!statuses.includes(req.body.status)) {
    return sendValidationError(res, {
      status: 'Неизвестный статус заявки',
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
      message: 'Для этого питомца уже одобрена другая заявка',
    });
  }

  item.status = req.body.status;

  if (req.body.note != null) {
    item.note = String(req.body.note);
  }

  res.json(item);
});

app.delete('/api/adoption-requests/:id', (req, res) => {
  const id = Number(req.params.id);
  const item = db.adoptionRequests.find(
    row => row.id === id && !row.deletedAt,
  );

  if (!item) {
    return res.status(404).json({
      message: 'Заявка не найдена',
    });
  }

  item.deletedAt = new Date().toISOString();
  res.status(204).end();
});

app.get('/api/medical-cards/:animalId', (req, res) => {
  const animalId = Number(req.params.animalId);

  if (!db.animals.some(
    item => item.id === animalId && !item.deletedAt,
  )) {
    return res.status(404).json({
      message: 'Питомец не найден',
    });
  }

  res.json(
    db.medicalCards[String(animalId)] ?? {
      animalId,
      passportNumber: '',
      microchipNumber: '',
      vaccinationNotes: '',
      allergies: '',
    },
  );
});

app.put('/api/medical-cards/:animalId', (req, res) => {
  const animalId = Number(req.params.animalId);

  if (!db.animals.some(
    item => item.id === animalId && !item.deletedAt,
  )) {
    return res.status(404).json({
      message: 'Питомец не найден',
    });
  }

  const card = {
    animalId,
    passportNumber: String(req.body.passportNumber ?? ''),
    microchipNumber: String(req.body.microchipNumber ?? ''),
    vaccinationNotes: String(req.body.vaccinationNotes ?? ''),
    allergies: String(req.body.allergies ?? ''),
  };

  db.medicalCards[String(animalId)] = card;
  res.json(card);
});

app.delete('/api/medical-cards/:animalId', (req, res) => {
  delete db.medicalCards[String(Number(req.params.animalId))];
  res.status(204).end();
});

app.get('/api/__health', (req, res) => {
  res.json({
    status: 'ok',
    time: new Date().toISOString(),
  });
});

app.post('/api/__reset', (req, res) => {
  seedData();

  res.json({
    message: 'Демонстрационные данные восстановлены',
  });
});

app.use('/api', (req, res, next) => {
  if (req.path === '/__health') {
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

  next();
});

app.use('/api', (req, res) => {
  res.status(404).json({
    message: 'Маршрут API не найден',
  });
});

app.use((error, req, res, next) => {
  console.error('[API error]', error.message);

  if (res.headersSent) {
    return next(error);
  }

  res.status(error.status || 500).json({
    message:
      error.status === 400
        ? 'Некорректный JSON в запросе'
        : 'Внутренняя ошибка сервера',
  });
});

seedData();

app.listen(PORT, () => {
  console.log(`API «Лапки и дом»: http://localhost:${PORT}/api`);
  console.log(`Разрешённый источник: ${ALLOWED_ORIGIN}`);
  console.log('Для проверки откройте /api/__health');
});