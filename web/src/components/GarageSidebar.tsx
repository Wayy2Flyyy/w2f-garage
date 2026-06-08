import type { Garage } from '../data/mockVehicles'

type Props = {
  garages: Record<string, Garage>
  selectedGarageId?: string
  onSelect: (garageId: string) => void
}

export function GarageSidebar({ garages, selectedGarageId, onSelect }: Props) {
  return (
    <aside className="garage-sidebar">
      <div className="brand-block">
        <span className="eyebrow">W2F</span>
        <h1>Garage Control</h1>
        <p>Vehicle authority dashboard</p>
      </div>

      <nav className="garage-list" aria-label="Garages">
        {Object.values(garages).map((garage) => (
          <button
            key={garage.id}
            className={`garage-button ${selectedGarageId === garage.id ? 'active' : ''}`}
            onClick={() => onSelect(garage.id)}
            type="button"
          >
            <span>{garage.label}</span>
            <small>{garage.type}</small>
          </button>
        ))}
      </nav>
    </aside>
  )
}
