import { useMemo, useState } from 'react'
import { fetchNui } from '../hooks/useNuiEvent'
import { StatusBadge } from '../components/StatusBadge'

export type PublicVehicle = {
  plate: string
  model?: string | number
  storedGarageLabel?: string
  state?: string
  fuel?: number
  engineHealth?: number
  bodyHealth?: number
  storedForHours?: number
  storedForDays?: number
  dailyFee?: number
  unpaidFee?: number
  canSpawn?: boolean
}

type PublicGaragePayload = {
  vehicles?: PublicVehicle[]
  garage?: {
    id?: string
    label?: string
    dailyVehicleFee?: number
    unlimitedStorage?: boolean
    sharedPublicStorage?: boolean
  }
  totalUnpaidFees?: number
  dailyVehicleFee?: number
}

type Props = {
  garageId: string
  data?: PublicGaragePayload
  onRefresh?: (payload: PublicGaragePayload) => void
}

export function PublicGarageDashboard({ garageId, data, onRefresh }: Props) {
  const [search, setSearch] = useState('')
  const [busy, setBusy] = useState(false)

  const vehicles = data?.vehicles ?? []
  const dailyFee = data?.dailyVehicleFee ?? data?.garage?.dailyVehicleFee ?? 700

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()

    if (!q) {
      return vehicles
    }

    return vehicles.filter((vehicle) => {
      const plate = vehicle.plate?.toLowerCase() ?? ''
      const model = String(vehicle.model ?? '').toLowerCase()
      return plate.includes(q) || model.includes(q)
    })
  }, [vehicles, search])

  const spawn = async (plate: string, payFirst = false) => {
    setBusy(true)

    try {
      if (payFirst) {
        await fetchNui('payPublicFee', { garageId, plate })
      }

      const result = await fetchNui<{ success?: boolean }>('spawnVehicle', { garageId, plate })

      if (result?.success) {
        const refreshed = await fetchNui<PublicGaragePayload>('refreshPublicGarage', { garageId })
        onRefresh?.(refreshed as PublicGaragePayload)
      }
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="public-layout">
      <header className="public-header">
        <div>
          <h2>{data?.garage?.label ?? 'Public Garage'}</h2>
          <p>Unlimited Storage · ${dailyFee}/day per vehicle</p>
          {data?.garage?.sharedPublicStorage && <small>Shared storage across all public garages</small>}
        </div>
        <div className="public-totals">
          <span>Unpaid total</span>
          <strong>${(data?.totalUnpaidFees ?? 0).toLocaleString()}</strong>
        </div>
      </header>

      <div className="public-toolbar">
        <input
          type="search"
          placeholder="Search plate or model..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </div>

      <div className="public-grid">
        {filtered.length === 0 ? (
          <p className="empty-copy">No vehicles in public storage.</p>
        ) : (
          filtered.map((vehicle) => (
            <article key={vehicle.plate} className="public-vehicle-card">
              <div className="public-vehicle-top">
                <div>
                  <strong>{vehicle.plate}</strong>
                  <span>{String(vehicle.model ?? 'Vehicle')}</span>
                </div>
                <StatusBadge state={vehicle.unpaidFee ? 'impounded' : 'stored'} />
              </div>

              <dl className="public-stats">
                <div>
                  <dt>Storage Fee</dt>
                  <dd>${vehicle.dailyFee ?? dailyFee}/day</dd>
                </div>
                <div>
                  <dt>Unpaid Fee</dt>
                  <dd>${(vehicle.unpaidFee ?? 0).toLocaleString()}</dd>
                </div>
                <div>
                  <dt>Stored For</dt>
                  <dd>
                    {vehicle.storedForDays ?? 0}d · {vehicle.storedForHours ?? 0}h
                  </dd>
                </div>
                <div>
                  <dt>Location</dt>
                  <dd>{vehicle.storedGarageLabel ?? '—'}</dd>
                </div>
                <div>
                  <dt>Fuel</dt>
                  <dd>{Math.round(vehicle.fuel ?? 0)}%</dd>
                </div>
                <div>
                  <dt>Condition</dt>
                  <dd>
                    E {Math.round(vehicle.engineHealth ?? 1000) / 10}% · B{' '}
                    {Math.round(vehicle.bodyHealth ?? 1000) / 10}%
                  </dd>
                </div>
              </dl>

              <div className="public-actions">
                {(vehicle.unpaidFee ?? 0) > 0 ? (
                  <button type="button" disabled={busy} onClick={() => spawn(vehicle.plate, true)}>
                    Pay & Spawn · ${(vehicle.unpaidFee ?? 0).toLocaleString()}
                  </button>
                ) : (
                  <button type="button" disabled={busy} onClick={() => spawn(vehicle.plate)}>
                    Spawn Vehicle
                  </button>
                )}
              </div>
            </article>
          ))
        )}
      </div>
    </div>
  )
}
