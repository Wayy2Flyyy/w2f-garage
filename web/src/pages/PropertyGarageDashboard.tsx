import { useMemo, useState } from 'react'
import { fetchNui } from '../hooks/useNuiEvent'
import { StatusBadge } from '../components/StatusBadge'

type PropertyGarage = {
  id: string
  label: string
  propertyClass: string
  price: number
  vehicleCapacity: number
  bicycleCapacity: number
  location?: string
  area?: string
  owned?: boolean
  usedSlots?: number
  freeSlots?: number
  productionReady?: boolean
  interiorEnterReady?: boolean
  interiorTemplate?: string
  floors?: number
}

export type PropertyDashboardData = {
  owned: PropertyGarage[]
  purchasable: PropertyGarage[]
  allowMultiple?: boolean
  maxOwned?: number
  publicMode?: boolean
}

type Props = {
  dashboard?: PropertyDashboardData
  selectedGarageId?: string
  onSelectGarage: (id: string) => void
}

const classLabels: Record<string, string> = {
  'low-end': 'Low-End',
  medium: 'Medium',
  'high-end': 'High-End',
  'high-end-custom': 'Eclipse Custom'
}

export function PropertyGarageDashboard({ dashboard, selectedGarageId, onSelectGarage }: Props) {
  const [tab, setTab] = useState<'owned' | 'buy'>('owned')
  const [busy, setBusy] = useState(false)

  const selected = useMemo(() => {
    const all = [...(dashboard?.owned ?? []), ...(dashboard?.purchasable ?? [])]
    return all.find((g) => g.id === selectedGarageId) ?? all[0]
  }, [dashboard, selectedGarageId])

  const list = tab === 'owned' ? dashboard?.owned ?? [] : dashboard?.purchasable ?? []

  const run = async (action: string, payload: Record<string, unknown>) => {
    setBusy(true)
    try {
      await fetchNui(action, payload)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="property-layout">
      <aside className="property-sidebar">
        <div className="property-tabs">
          <button type="button" className={tab === 'owned' ? 'active' : ''} onClick={() => setTab('owned')}>
            Owned ({dashboard?.owned?.length ?? 0})
          </button>
          <button type="button" className={tab === 'buy' ? 'active' : ''} onClick={() => setTab('buy')}>
            Buy ({dashboard?.purchasable?.length ?? 0})
          </button>
        </div>

        <div className="property-list">
          {list.map((garage) => (
            <button
              key={garage.id}
              type="button"
              className={`property-card ${selected?.id === garage.id ? 'selected' : ''}`}
              onClick={() => onSelectGarage(garage.id)}
            >
              <div>
                <strong>{garage.label}</strong>
                <span>{classLabels[garage.propertyClass] ?? garage.propertyClass}</span>
              </div>
              <small>
                {garage.usedSlots ?? 0}/{garage.vehicleCapacity} slots
              </small>
            </button>
          ))}
        </div>
      </aside>

      <main className="property-detail">
        {selected ? (
          <>
            <header>
              <div>
                <h2>{selected.label}</h2>
                <p>
                  {selected.location} · {selected.area}
                </p>
              </div>
              <StatusBadge state={selected.productionReady ? 'stored' : selected.interiorEnterReady ? 'out' : 'unknown'} />
            </header>

            <div className="property-stats">
              <article>
                <span>Class</span>
                <strong>{classLabels[selected.propertyClass] ?? selected.propertyClass}</strong>
              </article>
              <article>
                <span>Price</span>
                <strong>${selected.price?.toLocaleString()}</strong>
              </article>
              <article>
                <span>Capacity</span>
                <strong>
                  {selected.vehicleCapacity} vehicles · {selected.bicycleCapacity} bikes
                </strong>
              </article>
              <article>
                <span>Slots</span>
                <strong>
                  {selected.usedSlots ?? 0} used · {selected.freeSlots ?? selected.vehicleCapacity} free
                </strong>
              </article>
              <article>
                <span>Interior</span>
                <strong>{selected.interiorTemplate ?? '—'}</strong>
              </article>
              {selected.floors ? (
                <article>
                  <span>Floors</span>
                  <strong>{selected.floors}</strong>
                </article>
              ) : null}
            </div>

            {!selected.productionReady && (
              <div className="property-warning">
                {selected.interiorEnterReady
                  ? 'Shared interior base is active. Store, spawn, and slot positions still need TODO_CAPTURE.'
                  : 'Coordinates pending (TODO_CAPTURE). Purchase works; interior entry needs a base or captured coords.'}
              </div>
            )}

            <div className="property-actions">
              {selected.owned ? (
                <>
                  <button
                    type="button"
                    disabled={busy || !selected.interiorEnterReady}
                    onClick={() => run('enterGarage', { garageId: selected.id, floorIndex: 1 })}
                  >
                    Enter Garage
                  </button>
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => run('getGarageVehicles', { garageId: selected.id, floorIndex: 1 })}
                  >
                    Refresh Vehicles
                  </button>
                  {dashboard?.allowMultiple !== false && (
                    <button type="button" disabled={busy} className="ghost" onClick={() => run('sellGarage', { garageId: selected.id })}>
                      Sell Property
                    </button>
                  )}
                </>
              ) : (
                <button type="button" disabled={busy} onClick={() => run('buyGarage', { garageId: selected.id })}>
                  Buy Garage · ${selected.price?.toLocaleString()}
                </button>
              )}
            </div>
          </>
        ) : (
          <p className="empty-copy">Select a property garage.</p>
        )}
      </main>
    </div>
  )
}
