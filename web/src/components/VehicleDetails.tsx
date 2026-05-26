import type { Vehicle } from '../data/mockVehicles'
import { StatusBadge } from './StatusBadge'

type Props = {
  vehicle?: Vehicle
  onSpawn: () => void
  onStore: () => void
  onRecover: () => void
  onPayImpound: () => void
}

function HealthBar({ label, value, max = 1000 }: { label: string; value: number; max?: number }) {
  const percent = Math.max(0, Math.min(100, (value / max) * 100))

  return (
    <div className="health-row">
      <div>
        <span>{label}</span>
        <strong>{Math.round(percent)}%</strong>
      </div>
      <div className="metric-track">
        <span style={{ width: `${percent}%` }} />
      </div>
    </div>
  )
}

export function VehicleDetails({ vehicle, onSpawn, onStore, onRecover, onPayImpound }: Props) {
  if (!vehicle) {
    return (
      <aside className="details-panel muted-panel">
        <p>Select a vehicle to inspect state, fuel, damage, and available actions.</p>
      </aside>
    )
  }

  return (
    <aside className="details-panel">
      <div className="details-header">
        <div>
          <span className="eyebrow">Selected vehicle</span>
          <h2>{vehicle.model}</h2>
        </div>
        <StatusBadge state={vehicle.state} />
      </div>

      <div className="plate-display">{vehicle.plate}</div>

      <div className="details-grid">
        <span>Class</span>
        <strong>{vehicle.classLabel}</strong>
        <span>Mileage</span>
        <strong>{vehicle.mileage ? `${vehicle.mileage.toLocaleString()} mi` : 'Not tracked'}</strong>
        <span>Garage</span>
        <strong>{vehicle.garage}</strong>
      </div>

      <HealthBar label="Fuel" value={vehicle.fuel} max={100} />
      <HealthBar label="Engine" value={vehicle.engine} />
      <HealthBar label="Body" value={vehicle.body} />

      <div className="action-grid">
        <button type="button" onClick={onSpawn} disabled={vehicle.state !== 'stored'}>
          Spawn
        </button>
        <button type="button" onClick={onStore}>
          Store
        </button>
        <button type="button" onClick={onPayImpound} disabled={vehicle.state !== 'impounded'}>
          Pay impound
        </button>
        <button type="button" onClick={onRecover}>
          Recover
        </button>
        <button type="button" disabled>
          Transfer
        </button>
        <button type="button" disabled>
          {vehicle.favourite ? 'Favourited' : 'Favourite'}
        </button>
      </div>
    </aside>
  )
}
