-- Types
-- Stephen Leitnick
-- December 20, 2021

export type Args = {
	n: number,
	[any]: any,
}

export type FnBind = (Instance, ...any) -> ...any

export type ServerMiddlewareFn = (Instance, Args) -> (boolean, ...any)
export type ServerMiddleware = { ServerMiddlewareFn }

export type ClientMiddlewareFn = (Args) -> (boolean, ...any)
export type ClientMiddleware = { ClientMiddlewareFn }

export type SignalLimits = {
	AllowMissingArgs :boolean, -- Max calls within 1 sec before suspicious
	BrustTolerance :number, -- Max calls within 1 sec before suspicious
	PunishThreshold :number -- Only kick if absolutely malicious
}
return nil
