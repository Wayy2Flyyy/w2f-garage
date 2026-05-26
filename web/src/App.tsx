import { useCallback, useMemo, useState, type CSSProperties } from 'react'
import { GarageDashboard } from './pages/GarageDashboard'
import { PropertyGarageDashboard, type PropertyDashboardData } from './pages/PropertyGarageDashboard'
import { fetchNui, isFiveM, useNuiEvent } from './hooks/useNuiEvent'
import { mockGarages, mockVehicles, type Garage, type Vehicle } from './data/mockVehicles'

type OpenPayload = {
  garageId?: string
  garage?: Garage
  config?: {
    title?: string
    subtitle?: string
    accent?: string
  }
}

function isGarage(payload: Record<string, Garage> | Garage): payload is Garage {
  return typeof (payload as Garage).id === 'string'
}

export default function App() {
  const [visible, setVisible] = useState(!isFiveM())
  const [mode, setMode] = useState<'garage' | 'property'>(!isFiveM() ? 'property' : 'garage')
  const [garages, setGarages] = useState<Record<string, Garage>>(mockGarages)
  const [vehicles, setVehicles] = useState<Vehicle[]>(isFiveM() ? [] : mockVehicles)
  const [propertyDashboard, setPropertyDashboard] = useState<PropertyDashboardData>()
  const [selectedGarageId, setSelectedGarageId] = useState<string>('legion_public')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string>()
  const [config, setConfig] = useState({
    title: 'Garage Control',
    subtitle: 'Vehicle management dashboard',
    accent: '#d7ff3f'
  })

  useNuiEvent<OpenPayload>(
    'openGarage',
    useCallback((payload) => {
      setMode('garage')
      setVisible(true)
      setError(undefined)

      if (payload?.garageId) {
        setSelectedGarageId(payload.garageId)
      }

      if (payload?.garage) {
        setGarages((current) => ({
          ...current,
          [payload.garage!.id]: payload.garage!
        }))
      }

      if (payload?.config) {
        setConfig((current) => ({
          ...current,
          ...payload.config
        }))
      }
    }, [])
  )

  useNuiEvent<{ garageId?: string; dashboard?: PropertyDashboardData; config?: OpenPayload['config'] }>(
    'openPropertyGarage',
    useCallback((payload) => {
      setMode('property')
      setVisible(true)
      setError(undefined)

      if (payload?.garageId) {
        setSelectedGarageId(payload.garageId)
      }

      if (payload?.dashboard) {
        setPropertyDashboard(payload.dashboard)
      }

      if (payload?.config) {
        setConfig((current) => ({
          ...current,
          ...payload.config
        }))
      }
    }, [])
  )

  useNuiEvent<void>(
    'closeGarage',
    useCallback(() => {
      setVisible(false)
    }, [])
  )

  useNuiEvent<Record<string, Garage> | Garage>(
    'setGarageData',
    useCallback((payload) => {
      if (payload && Object.keys(payload).length > 0) {
        if (isGarage(payload)) {
          setGarages((current) => ({
            ...current,
            [payload.id]: payload
          }))
          return
        }

        setGarages(payload)
      }
    }, [])
  )

  useNuiEvent<PropertyDashboardData>(
    'setPropertyDashboard',
    useCallback((payload) => {
      setPropertyDashboard(payload)
    }, [])
  )

  useNuiEvent<Vehicle[]>(
    'setVehicles',
    useCallback((payload) => {
      setVehicles(Array.isArray(payload) ? payload : [])
    }, [])
  )

  useNuiEvent<boolean>(
    'setLoading',
    useCallback((payload) => {
      setLoading(Boolean(payload))
    }, [])
  )

  useNuiEvent<string>(
    'setError',
    useCallback((payload) => {
      setError(payload)
    }, [])
  )

  useNuiEvent<string>(
    'notify',
    useCallback((payload) => {
      setError(payload)
    }, [])
  )

  const themeStyle = useMemo(
    () =>
      ({
        '--accent': config.accent
      }) as CSSProperties,
    [config.accent]
  )

  const handleClose = useCallback(() => {
    if (isFiveM()) {
      void fetchNui('close')
      return
    }

    setVisible(false)
  }, [])

  if (!visible) {
    return null
  }

  return (
    <div className="app-root" style={themeStyle}>
      <div className="ambient ambient-one" />
      <div className="ambient ambient-two" />

      <section className="tablet-frame">
        <header className="top-strip">
          <div>
            <span>{config.title}</span>
            <small>{config.subtitle}</small>
          </div>
          <button type="button" onClick={handleClose}>
            Close
          </button>
        </header>

        {loading && <div className="loading-bar">Loading garage data...</div>}
        {error && <div className="error-bar">{error}</div>}

        {mode === 'property' ? (
          <PropertyGarageDashboard
            dashboard={propertyDashboard}
            selectedGarageId={selectedGarageId}
            onSelectGarage={setSelectedGarageId}
          />
        ) : (
          <GarageDashboard
            garages={garages}
            vehicles={vehicles}
            selectedGarageId={selectedGarageId}
            onSelectGarage={setSelectedGarageId}
            onVehiclesChanged={setVehicles}
          />
        )}
      </section>
    </div>
  )
}
