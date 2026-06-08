import type { VehicleState } from '../data/mockVehicles'

const labels: Record<VehicleState, string> = {
  stored: 'Stored',
  out: 'Out',
  impounded: 'Impounded',
  destroyed: 'Destroyed',
  seized: 'Seized',
  repair: 'In repair',
  transferred: 'Transferred',
  unknown: 'Unknown'
}

export function StatusBadge({ state }: { state: VehicleState }) {
  return <span className={`status-badge status-${state}`}>{labels[state] ?? 'Unknown'}</span>
}
