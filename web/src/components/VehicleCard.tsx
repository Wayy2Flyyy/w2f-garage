import type { Vehicle } from '../data/mockVehicles'
import { StatusBadge } from './StatusBadge'

type Props = {
  vehicle: Vehicle
  selected: boolean
  onSelect: (vehicle: Vehicle) => void
}

export function VehicleCard({ vehicle, selected, onSelect }: Props) {
  return (
    <button
      className={`vehicle-card ${selected ? 'selected' : ''}`}
      type="button"
      onClick={() => onSelect(vehicle)}
    >
      <div className="vehicle-card-top">
        <StatusBadge state={vehicle.state} />
        <span className="plate">{vehicle.plate}</span>
      </div>
      <h3>{vehicle.model}</h3>
      <p>{vehicle.classLabel}</p>
      <div className="metric-row">
        <span>Fuel</span>
        <strong>{Math.round(vehicle.fuel)}%</strong>
      </div>
      <div className="metric-track">
        <span style={{ width: `${Math.max(0, Math.min(vehicle.fuel, 100))}%` }} />
      </div>
    </button>
  )
}
