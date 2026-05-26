import { useMemo, useState } from 'react'
import { EmptyState } from '../components/EmptyState'
import { GarageSidebar } from '../components/GarageSidebar'
import { VehicleCard } from '../components/VehicleCard'
import { VehicleDetails } from '../components/VehicleDetails'
import type { Garage, Vehicle } from '../data/mockVehicles'
import { fetchNui } from '../hooks/useNuiEvent'

type NuiResponse<T> = {
  success: boolean
  message?: string
  data?: T
}

type Props = {
  garages: Record<string, Garage>
  vehicles: Vehicle[]
  selectedGarageId?: string
  onSelectGarage: (garageId: string) => void
  onVehiclesChanged: (vehicles: Vehicle[]) => void
}

export function GarageDashboard({
  garages,
  vehicles,
  selectedGarageId,
  onSelectGarage,
  onVehiclesChanged
}: Props) {
  const [selectedPlate, setSelectedPlate] = useState<string>()
  const [search, setSearch] = useState('')
  const [notice, setNotice] = useState<string>()

  const filteredVehicles = useMemo(() => {
    const normalized = search.trim().toLowerCase()

    return vehicles.filter((vehicle) => {
      const matchesGarage = !selectedGarageId || vehicle.garage === selectedGarageId
      const matchesSearch =
        normalized === '' ||
        vehicle.plate.toLowerCase().includes(normalized) ||
        vehicle.model.toLowerCase().includes(normalized) ||
        vehicle.garage.toLowerCase().includes(normalized)

      return matchesGarage && matchesSearch
    })
  }, [search, selectedGarageId, vehicles])

  const selectedVehicle =
    filteredVehicles.find((vehicle) => vehicle.plate === selectedPlate) ?? filteredVehicles[0]

  async function refreshVehicles() {
    const response = await fetchNui<NuiResponse<Vehicle[]>>('getVehicles', {
      garageId: selectedGarageId
    })

    if (response.success && response.data) {
      onVehiclesChanged(response.data)
    }
  }

  async function runAction(action: string, payload: Record<string, unknown>) {
    const response = await fetchNui<NuiResponse<Vehicle[] | null>>(action, payload)
    setNotice(response.message ?? (response.success ? 'Action completed.' : 'Action failed.'))

    if (response.success) {
      await refreshVehicles()
    }
  }

  return (
    <main className="tablet-shell">
      <GarageSidebar garages={garages} selectedGarageId={selectedGarageId} onSelect={onSelectGarage} />

      <section className="content-panel">
        <header className="toolbar">
          <div>
            <span className="eyebrow">Live vehicle framework</span>
            <h2>{selectedGarageId ? garages[selectedGarageId]?.label ?? selectedGarageId : 'All garages'}</h2>
          </div>
          <input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search plate, model, or garage..."
          />
        </header>

        {notice && <div className="notice">{notice}</div>}

        {filteredVehicles.length === 0 ? (
          <EmptyState
            title="No vehicles found"
            message="This foundation returns empty data until database ownership loading is configured."
          />
        ) : (
          <div className="vehicle-grid">
            {filteredVehicles.map((vehicle) => (
              <VehicleCard
                key={vehicle.plate}
                vehicle={vehicle}
                selected={selectedVehicle?.plate === vehicle.plate}
                onSelect={(nextVehicle) => setSelectedPlate(nextVehicle.plate)}
              />
            ))}
          </div>
        )}
      </section>

      <VehicleDetails
        vehicle={selectedVehicle}
        onSpawn={() =>
          selectedVehicle &&
          runAction('spawnVehicle', {
            plate: selectedVehicle.plate,
            garageId: selectedGarageId
          })
        }
        onStore={() => runAction('storeVehicle', { garageId: selectedGarageId })}
        onRecover={() =>
          selectedVehicle &&
          runAction('recoverVehicle', {
            plate: selectedVehicle.plate,
            garageId: selectedGarageId
          })
        }
        onPayImpound={() =>
          selectedVehicle &&
          runAction('payImpound', {
            plate: selectedVehicle.plate,
            garageId: selectedGarageId
          })
        }
      />
    </main>
  )
}
