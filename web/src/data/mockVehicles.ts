export type VehicleState =
  | 'stored'
  | 'out'
  | 'impounded'
  | 'destroyed'
  | 'seized'
  | 'repair'
  | 'transferred'
  | 'unknown'

export type Garage = {
  id: string
  label: string
  type: string
  ui?: {
    accent?: string
    theme?: string
  }
}

export type Vehicle = {
  plate: string
  model: string
  garage: string
  state: VehicleState
  fuel: number
  engine: number
  body: number
  classLabel: string
  favourite?: boolean
  mileage?: number
  impoundFee?: number
}

export const mockGarages: Record<string, Garage> = {
  legion_public: {
    id: 'legion_public',
    label: 'Legion Square Garage',
    type: 'public',
    ui: {
      accent: '#d7ff3f',
      theme: 'premium-dark'
    }
  },
  city_depot: {
    id: 'city_depot',
    label: 'City Depot',
    type: 'depot',
    ui: {
      accent: '#ffb347',
      theme: 'premium-dark'
    }
  }
}

export const mockVehicles: Vehicle[] = [
  {
    plate: 'W2F 001',
    model: 'Elegy Retro Custom',
    garage: 'legion_public',
    state: 'stored',
    fuel: 82,
    engine: 935,
    body: 890,
    classLabel: 'Sports',
    favourite: true,
    mileage: 1432
  },
  {
    plate: 'W2F 911',
    model: 'Tailgater S',
    garage: 'legion_public',
    state: 'out',
    fuel: 46,
    engine: 812,
    body: 774,
    classLabel: 'Sedan',
    mileage: 887
  },
  {
    plate: 'W2F DEP',
    model: 'Sultan RS',
    garage: 'city_depot',
    state: 'impounded',
    fuel: 12,
    engine: 533,
    body: 481,
    classLabel: 'Sports',
    impoundFee: 750,
    mileage: 2204
  }
]
