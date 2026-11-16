// career.js – persistent career state (cash, unlocks, loadout, hidden packages, best times).
const KEY = 'br3.career';

export const AVAILABLE_CARS = ['BMW', 'AstonMartin', 'AudiR8', 'Corvette', 'DodgeRam', 'FordGT',
  'Marcos', 'MiniCooper', 'Mustang', 'Porsche', 'Seat', 'BlackTruck', 'Tank', 'Apache', 'Eclipse', 'Nissan'];

export function defaultCareer() {
  return {
    cash: 10000,
    cars: ['BMW'],
    primary: ['NoPrimary', 'MachineGun'],
    secondary: ['NoSecondary', 'RocketPod'],
    car: 'BMW',
    primaryWeapon: 'MachineGun',
    secondaryWeapon: 'RocketPod',
    hiddenPackages: [],
    bestTimes: {},
  };
}

export function loadCareer() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return defaultCareer();
    return Object.assign(defaultCareer(), JSON.parse(raw));
  } catch (e) { return defaultCareer(); }
}

export function saveCareer(c) {
  try { localStorage.setItem(KEY, JSON.stringify(c)); } catch (e) { /* private mode */ }
}

export function addCash(c, amount) { c.cash = Math.max(0, Math.round(c.cash + amount)); saveCareer(c); }

export function unlock(c, kind, id) {
  const list = kind === 'car' ? c.cars : kind === 'primary' ? c.primary : c.secondary;
  if (list.indexOf(id) < 0) { list.push(id); saveCareer(c); }
}

export function isUnlocked(c, kind, id) {
  const list = kind === 'car' ? c.cars : kind === 'primary' ? c.primary : c.secondary;
  return list.indexOf(id) >= 0;
}