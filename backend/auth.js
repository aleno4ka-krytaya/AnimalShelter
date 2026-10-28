'use strict';

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('node:crypto');

const JWT_SECRET =
  process.env.JWT_SECRET ||
  'animal-shelter-development-secret-change-before-deployment';

const REFRESH_TTL = 7 * 24 * 60 * 60;

function readArgument(name, fallback) {
  const index = process.argv.indexOf(name);

  return index >= 0 && process.argv[index + 1]
    ? process.argv[index + 1]
    : fallback;
}

const ACCESS_TTL = Math.max(
  1,
  Number(readArgument('--ttl', '900')) || 900,
);

const users = [];
const activeRefreshTokens = new Set();
let nextUserId = 1;

function publicUser(user) {
  return {
    id: user.id,
    username: user.username,
    email: user.email,
    fullName: user.fullName,
    role: user.role,
  };
}

function findUserById(id) {
  return users.find(user => user.id === Number(id));
}

function createUser({
  username,
  password,
  email,
  fullName,
  role,
}) {
  const user = {
    id: nextUserId++,
    username,
    passwordHash: bcrypt.hashSync(password, 10),
    email,
    fullName,
    role,
  };

  users.push(user);
  return user;
}

function seedUsers() {
  users.length = 0;
  activeRefreshTokens.clear();
  nextUserId = 1;

  createUser({
  username: 'admin',
  password: 'admin123',
  email: 'admin@shelter.local',
  fullName: 'Администратор приюта',
  role: 'admin',
  });

  createUser({
  username: 'staff',
  password: 'staff123',
  email: 'staff@shelter.local',
  fullName: 'Сотрудник приюта',
  role: 'staff',
  });

  createUser({
  username: 'visitor',
  password: 'visitor123',
  email: 'visitor@shelter.local',
  fullName: 'Посетитель приюта',
  role: 'visitor',
  });
}

function issueTokens(user) {
  const accessToken = jwt.sign(
    {
      sub: String(user.id),
      type: 'access',
    },
    JWT_SECRET,
    {
      expiresIn: ACCESS_TTL,
    },
  );

  const refreshToken = jwt.sign(
    {
      sub: String(user.id),
      type: 'refresh',
      nonce: crypto.randomUUID(),
    },
    JWT_SECRET,
    {
      expiresIn: REFRESH_TTL,
    },
  );

  activeRefreshTokens.add(refreshToken);

  return {
    accessToken,
    refreshToken,
    expiresIn: ACCESS_TTL,
    user: publicUser(user),
  };
}

function sendError(res, status, message, errors) {
  const body = { message };

  if (errors) {
    body.errors = errors;
  }

  return res.status(status).json(body);
}

function authenticate(req, res, next) {
  const header = req.headers.authorization || '';
  const match = header.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    return sendError(
      res,
      401,
      'Для выполнения операции необходимо войти в систему.',
    );
  }

  try {
    const payload = jwt.verify(match[1], JWT_SECRET);

    if (payload.type !== 'access') {
      return sendError(res, 401, 'Некорректный токен доступа.');
    }

    const user = findUserById(payload.sub);

    if (!user) {
      return sendError(res, 401, 'Пользователь не найден.');
    }

    req.user = publicUser(user);
    req.accessToken = match[1];

    next();
  } catch (_) {
    return sendError(
      res,
      401,
      'Токен недействителен или срок его действия истёк.',
    );
  }
}

function requireRoles(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return sendError(res, 401, 'Сначала войдите в систему.');
    }

    if (!allowedRoles.includes(req.user.role)) {
      return sendError(
        res,
        403,
        'У вашей роли нет прав для выполнения этой операции.',
      );
    }

    next();
  };
}

function attachAuthRoutes(app) {
  app.post('/api/auth/register', (req, res) => {
    const body = req.body || {};

    const username = String(body.username || '').trim();
    const email = String(body.email || '').trim();
    const fullName = String(body.fullName || '').trim();
    const password = String(body.password || '');

    const errors = {};

    if (!/^[a-zA-Z0-9_.-]{3,32}$/.test(username)) {
      errors.username =
        'Логин должен содержать от 3 до 32 латинских букв, цифр или символов ._-';
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      errors.email = 'Введите корректный адрес электронной почты';
    }

    if (!fullName) {
      errors.fullName = 'Введите имя';
    }

    if (password.length < 8) {
      errors.password = 'Пароль должен содержать не менее 8 символов';
    } else if (!/\d/.test(password)) {
      errors.password = 'Пароль должен содержать хотя бы одну цифру';
    } else if (!/[^a-zA-Z0-9]/.test(password)) {
      errors.password =
        'Пароль должен содержать хотя бы один специальный символ';
    }

    if (
      users.some(
        user =>
          user.username.toLowerCase() === username.toLowerCase(),
      )
    ) {
      errors.username = 'Такой логин уже зарегистрирован';
    }

    if (
      users.some(
        user => user.email.toLowerCase() === email.toLowerCase(),
      )
    ) {
      errors.email = 'Этот адрес электронной почты уже используется';
    }

    if (Object.keys(errors).length) {
      return sendError(res, 422, 'Проверьте введённые данные', errors);
    }

    const user = createUser({
      username,
      password,
      email,
      fullName,
      role: 'reader',
    });

    return res.status(201).json(publicUser(user));
  });

  app.post('/api/auth/login', async (req, res) => {
    const body = req.body || {};
    const username = String(body.username || '').trim();
    const password = String(body.password || '');

    const user = users.find(
      item =>
        item.username.toLowerCase() === username.toLowerCase(),
    );

    const validPassword =
      user && await bcrypt.compare(password, user.passwordHash);

    if (!validPassword) {
      return sendError(
        res,
        401,
        'Неверный логин или пароль.',
      );
    }

    return res.json(issueTokens(user));
  });

  app.post('/api/auth/refresh', (req, res) => {
    const token = String(req.body?.refreshToken || '');

    if (!activeRefreshTokens.has(token)) {
      return sendError(
        res,
        401,
        'Токен обновления недействителен или уже использован.',
      );
    }

    let payload;

    try {
      payload = jwt.verify(token, JWT_SECRET);
    } catch (_) {
      activeRefreshTokens.delete(token);

      return sendError(
        res,
        401,
        'Срок действия токена обновления истёк.',
      );
    }

    if (payload.type !== 'refresh') {
      activeRefreshTokens.delete(token);

      return sendError(res, 401, 'Некорректный токен обновления.');
    }

    const user = findUserById(payload.sub);

    if (!user) {
      activeRefreshTokens.delete(token);

      return sendError(res, 401, 'Пользователь не найден.');
    }

    activeRefreshTokens.delete(token);

    return res.json(issueTokens(user));
  });

  app.get('/api/auth/me', authenticate, (req, res) => {
    res.json(req.user);
  });

  app.post('/api/auth/logout', (req, res) => {
    const token = String(req.body?.refreshToken || '');

    if (token) {
      activeRefreshTokens.delete(token);
    }

    res.status(204).end();
  });

  app.get(
    '/api/auth/users',
    authenticate,
    requireRoles('admin'),
    (req, res) => {
      res.json(users.map(publicUser));
    },
  );

  app.put(
    '/api/auth/users/:id/role',
    authenticate,
    requireRoles('admin'),
    (req, res) => {
      const user = findUserById(req.params.id);
      const role = String(req.body?.role || '');

      if (!user) {
        return sendError(res, 404, 'Пользователь не найден.');
      }

      if (!['reader', 'librarian', 'admin'].includes(role)) {
        return sendError(
          res,
          422,
          'Недопустимая роль пользователя.',
          { role: 'Выберите reader, librarian или admin' },
        );
      }

      user.role = role;

      res.json(publicUser(user));
    },
  );
}

function createAuth(app) {
  seedUsers();
  attachAuthRoutes(app);

  return {
    authenticate,
    requireRoles,
  };
}

module.exports = {
  createAuth,
};