
const test = require('node:test');
const assert = require('node:assert/strict');

const {
  validateAnimal,
  validateAdopter,
  db,
} = require('../server');

test('Животное с корректными данными проходит валидацию', () => {
  const errors = validateAnimal({
    name: 'Барсик',
    species: 'Кошка',
    breed: 'Домашняя',
    age: 3,
    sex: 'Самец',
    status: 'Ищет дом',
  });

  assert.deepEqual(errors, {});
});

test('Валидатор животного обнаруживает пустую кличку', () => {
  const errors = validateAnimal({
    name: '   ',
    species: 'Кошка',
    breed: 'Домашняя',
    age: 3,
    sex: 'Самец',
    status: 'Ищет дом',
  });

  assert.ok(errors.name);
});

test('Валидатор животного отклоняет некорректный возраст', () => {
  const errors = validateAnimal({
    name: 'Барсик',
    species: 'Кошка',
    breed: 'Домашняя',
    age: -1,
    sex: 'Самец',
    status: 'Ищет дом',
  });

  assert.ok(errors.age);
});

test('Валидатор животного отклоняет неизвестный вид', () => {
  const errors = validateAnimal({
    name: 'Барсик',
    species: 'Дракон',
    breed: 'Домашняя',
    age: 3,
    sex: 'Самец',
    status: 'Ищет дом',
  });

  assert.ok(errors.species);
});

test('Валидатор усыновителя отклоняет некорректный email', () => {
  const errors = validateAdopter({
    fullName: 'Иван Иванов',
    city: 'Москва',
    phone: '+79990000000',
    email: 'wrong-email',
    preferredSpecies: 'Кошка',
  });

  assert.ok(errors.email);
});

test('Валидатор усыновителя обнаруживает отсутствующие данные', () => {
  const errors = validateAdopter({});

  assert.ok(errors.fullName);
  assert.ok(errors.city);
  assert.ok(errors.phone);
  assert.ok(errors.email);
  assert.ok(errors.preferredSpecies);
});

test('Валидатор усыновителя принимает корректные данные', () => {
  const errors = validateAdopter({
    fullName: 'Иван Иванов',
    city: 'Москва',
    phone: '+79990000000',
    email: 'ivan-test@example.com',
    preferredSpecies: 'Кошка',
  });

  assert.deepEqual(errors, {});
});
