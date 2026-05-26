import { useEffect } from 'react'

export function isFiveM(): boolean {
  return typeof window !== 'undefined' && 'invokeNative' in window
}

export function getResourceName(): string {
  if (typeof window === 'undefined') {
    return 'w2f-garage'
  }

  const globalWindow = window as Window & {
    GetParentResourceName?: () => string
  }

  return globalWindow.GetParentResourceName?.() ?? 'w2f-garage'
}

export async function fetchNui<TResponse>(
  eventName: string,
  data: unknown = {}
): Promise<TResponse> {
  if (!isFiveM()) {
    return {
      success: true,
      data: null
    } as TResponse
  }

  const response = await fetch(`https://${getResourceName()}/${eventName}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8'
    },
    body: JSON.stringify(data)
  })

  return response.json() as Promise<TResponse>
}

export function useNuiEvent<TPayload>(
  action: string,
  handler: (payload: TPayload) => void
): void {
  useEffect(() => {
    const listener = (event: MessageEvent<{ action: string; payload: TPayload }>) => {
      if (event.data?.action === action) {
        handler(event.data.payload)
      }
    }

    window.addEventListener('message', listener)

    return () => {
      window.removeEventListener('message', listener)
    }
  }, [action, handler])
}
