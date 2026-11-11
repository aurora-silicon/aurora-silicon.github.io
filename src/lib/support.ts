import supportData from '../data/support.json';

export type State = 'works' | 'partial' | 'none' | 'unknown';
export type Os = 'linux' | 'windows';
export interface Device {
  model: string; device: string; chip: string; soc: string; year: string;
  generation: string; discussion: string; profile: string;
}
export interface FeatureGroup { name: string; features: string[]; }
export interface Record { state: Exclude<State, 'unknown'>; note: string; }
type Results = { [device: string]: { [feature: string]: Record } };
export const deviceClasses = ['MacBook Air', 'MacBook Neo', 'MacBook Pro', 'Mac mini', 'Mac Studio', 'Mac Pro', 'iMac'];
export function getDeviceClass(device: Device): string {
  return deviceClasses.find(name => device.model.startsWith(name)) ?? device.model;
}
export const support = supportData as {
  profiles: { [profile: string]: FeatureGroup[] };
  results: Results;
  series: string[];
  windows: { source: string; results: Results };
};
// Linux and Windows results are recorded separately for the same Macs and
// the same feature list.
export const osLabels: { [os in Os]: string } = { linux: 'Linux', windows: 'Windows' };
export const osList: Os[] = ['linux', 'windows'];
export function getResults(os: Os = 'linux'): Results {
  return os === 'windows' ? support.windows.results : support.results;
}
export function getRecord(device: string, feature: string, os: Os = 'linux'): Record | undefined {
  return getResults(os)[device]?.[feature];
}
export function hasResults(device: string, os: Os): boolean {
  return Boolean(getResults(os)[device]);
}
// Chip series, newest first, as the Support page tabs show them.
export function getSeries(devices: Device[]): string[] {
  return support.series.filter(series => devices.some(device => device.generation === series));
}
// Pro, Max and Ultra chips are told apart within a series, after the base chip.
const chipTiers = ['Pro', 'Max', 'Ultra'];
export function getChipTier(device: Device): number {
  const tier = device.chip.match(/\b(Pro|Max|Ultra)\b/)?.[1];
  return tier ? chipTiers.indexOf(tier) + 1 : 0;
}
export const labels: { [state in State]: string } = {
  works: 'Working', partial: 'Partial', none: 'Not working', unknown: 'Not recorded',
};
// A note is one line per part in the form "State: part." A plain note gets
// the feature's own state in front of it; no note means the state alone.
const partPattern = /^(Working|Partial|Not working): /;
export function noteLines(record: Record | undefined, os: Os = 'linux'): string[] {
  if (!record) return [`No ${osLabels[os]} result recorded for this device.`];
  const lines = record.note.split('\n').map(line => line.trim()).filter(Boolean);
  if (!lines.length) return [`${labels[record.state]}.`];
  return lines.map(line => {
    const text = partPattern.test(line) ? line : `${labels[record.state]}: ${line}`;
    return text.endsWith('.') ? text : `${text}.`;
  });
}
export function getState(device: string, feature: string, os: Os = 'linux'): State {
  return getRecord(device, feature, os)?.state ?? 'unknown';
}
export function getGroups(device: Device, _os: Os = 'linux'): FeatureGroup[] {
  let groups = support.profiles[device.profile] ?? support.profiles.laptop;
  if (device.generation === 'M1' || device.generation === 'M2') {
    groups = groups.map(group => {
      const features = group.features.filter(feature => feature !== 'Ray tracing');
      if (group.name === 'Platform') return { ...group, features: [...features, 'Secure Enclave'] };
      if (group.name === 'Display' || group.name === 'Display and input') return { ...group, features: [...features, 'USB-C display', 'Variable refresh rate'] };
      return { ...group, features };
    });
  }
  if (device.generation === 'M4' && device.profile === 'imac') {
    groups = groups.map(group => group.name === 'Display' ? { ...group, features: [...new Set([...group.features, 'External display'])] } : group);
  }
  if ((device.generation === 'M4' && ['desktop', 'imac'].includes(device.profile)) ||
      (['M5 Pro', 'M5 Max'].includes(device.chip) && device.profile === 'desktop')) {
    groups = groups.map(group => group.name === 'Power' ? { ...group, features: [...new Set([...group.features, 'Fan control'])] } : group);
  }
  return groups;
}
export function getSummary(device: Device, os: Os = 'linux') {
  const features = getGroups(device, os).flatMap(group => group.features);
  const state = (feature: string) => getState(device.device, feature, os);
  return {
    total: features.length,
    working: features.filter(feature => state(feature) === 'works').length,
    partial: features.filter(feature => state(feature) === 'partial').length,
    notWorking: features.filter(feature => state(feature) === 'none').length,
    recorded: features.filter(feature => state(feature) !== 'unknown').length,
  };
}
