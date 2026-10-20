import supportData from '../data/support.json';
import historyData from '../data/feature-reports.json';

export type State = 'works' | 'partial' | 'none' | 'unknown' | 'reported';
export interface Device {
  model: string; device: string; chip: string; soc: string; year: string;
  generation: string; discussion: string; profile: string;
}
export interface FeatureGroup { name: string; features: string[]; }
export interface Record { state: Exclude<State, 'unknown' | 'reported'>; note: string; }
export interface History { date: string; title: string; detail: string; url: string; }
export const deviceClasses = ['MacBook Air', 'MacBook Neo', 'MacBook Pro', 'Mac mini', 'Mac Studio', 'Mac Pro', 'iMac'];
export function getDeviceClass(device: Device): string {
  return deviceClasses.find(name => device.model.startsWith(name)) ?? device.model;
}
export const chipFamilies = ['M1', 'M2', 'M3', 'M4', 'A18 Pro', 'M5', 'M6'];
export function getChipGroup(device: Device): string {
  if (/^M\d+ (Pro|Max)/.test(device.chip)) return `${device.generation} Pro/Max`;
  if (/^M\d+ Ultra/.test(device.chip)) return `${device.generation} Ultra`;
  return device.generation;
}
export function getChipGroups(devices: Device[]): { family: string; options: string[] }[] {
  return chipFamilies.map(family => ({
    family,
    options: [family, `${family} Pro/Max`, `${family} Ultra`].filter(option => devices.some(device => getChipGroup(device) === option)),
  })).filter(group => group.options.length);
}
export const support = supportData as {
  profiles: { [profile: string]: FeatureGroup[] };
  results: { [device: string]: { [feature: string]: Record } };
  series: string[];
};
export const history = historyData as { [device: string]: { [feature: string]: History[] } };
export const labels: { [state in State]: string } = {
  works: 'Working', partial: 'Partial', none: 'Not working', unknown: 'Not recorded', reported: 'Reported',
};
const historyKeys: { [feature: string]: string } = {
  Boot: 'boot', 'GPU acceleration': 'graphics', 'Internal display': 'display',
  'Internal storage': 'storage', Keyboard: 'keyboard', Trackpad: 'trackpad',
  'Wi-Fi': 'wifi', Bluetooth: 'bluetooth', Speakers: 'audio', Camera: 'camera',
  'USB-C': 'usb', 'Thunderbolt / USB4': 'thunderbolt', 'Touch ID': 'touch-id',
  'Sleep / resume': 'suspend', 'Neural Engine': 'neural-engine',
};
export function getHistory(device: string, feature: string): History[] {
  return history[device]?.[historyKeys[feature]] ?? [];
}
export function getState(device: string, feature: string): State {
  return support.results[device]?.[feature]?.state ?? (getHistory(device, feature).length ? 'reported' : 'unknown');
}
export function getGroups(device: Device): FeatureGroup[] {
  let groups = support.profiles[device.profile] ?? support.profiles.laptop;
  if (device.generation === 'M1' || device.generation === 'M2') {
    groups = groups.map(group => {
      if (group.name === 'Platform') return { ...group, features: [...group.features, 'Secure Enclave'] };
      if (group.name === 'Display' || group.name === 'Display and input') return { ...group, features: [...group.features, 'USB-C display', 'Variable refresh rate'] };
      return group;
    });
  }
  if (device.chip === 'M5 Pro' && device.profile === 'desktop') {
    groups = groups.map(group => group.name === 'Power' ? { ...group, features: [...group.features, 'Fan control'] } : group);
  }
  return getHistory(device.device, 'Neural Engine').length
    ? [...groups, { name: 'Research', features: ['Neural Engine'] }]
    : groups;
}
export function getSummary(device: Device) {
  const features = getGroups(device).flatMap(group => group.features);
  return {
    total: features.length,
    working: features.filter(feature => getState(device.device, feature) === 'works').length,
    partial: features.filter(feature => getState(device.device, feature) === 'partial').length,
    notWorking: features.filter(feature => getState(device.device, feature) === 'none').length,
    reported: features.filter(feature => getState(device.device, feature) === 'reported').length,
    recorded: features.filter(feature => getState(device.device, feature) !== 'unknown').length,
  };
}
