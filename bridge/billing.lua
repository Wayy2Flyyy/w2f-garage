Billing = Billing or {}

local function cfg()
    return Config.PublicGarages or {}
end

local function providers()
    return Config.BillingProviders or {}
end

function Billing.GetProvider()
    local selected = cfg().billingProvider or 'auto'
    if selected ~= 'auto' then
        return selected
    end

    local p = providers()
    if p.lb_phone and p.lb_phone.enabled ~= false and GetResourceState((p.lb_phone.resource or 'lb-phone')) == 'started' then
        return 'lb_phone'
    end
    if p.qbox and p.qbox.enabled ~= false and GetResourceState((p.qbox.resource or 'qbx_core')) == 'started' then
        return 'qbox'
    end

    return 'internal'
end

function Billing.CreateBill(source, billData)
    local provider = Billing.GetProvider()

    if provider == 'lb_phone' then
        local lb = providers().lb_phone or {}
        if lb.sendNotification and GetResourceState(lb.resource or 'lb-phone') == 'started' then
            pcall(function()
                TriggerEvent('lb-phone:server:sendNotification', source, {
                    title = lb.notificationTitle or 'Garage Fee Due',
                    message = lb.notificationMessage or 'You have an unpaid public garage storage fee.'
                })
            end)
        end

        Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_BILLING_FALLBACK, source, billData.plate, billData.garageId, { provider = 'lb_phone_notification_only' })
        provider = 'internal'
    end

    if provider == 'qbox' then
        Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_BILLING_FALLBACK, source, billData.plate, billData.garageId, { provider = 'qbox_internal_fallback' })
        provider = 'internal'
    end

    return { success = true, provider = provider, providerBillId = nil }
end

function Billing.GetOutstandingBills(source)
    local identifier = Bridge.GetIdentifier(source)
    if not identifier then return {} end
    return Database.GetPublicGarageBillsByOwner(identifier, 'pending')
end

function Billing.MarkPaid(billId, providerBillId)
    return Database.MarkPublicGarageBillPaid(billId)
end

function Billing.CancelBill(billId)
    return Database.UpdatePublicGarageBillStatus(billId, 'cancelled')
end

function Billing.IsBillPaid(billId)
    return false
end

function Billing.OpenBillingApp(source)
    local provider = Billing.GetProvider()
    if provider == 'lb_phone' then
        return ServerUtils.Success({ provider = provider, opened = true })
    end

    if provider == 'qbox' then
        return ServerUtils.Success({ provider = provider, opened = true })
    end

    return ServerUtils.Success({ provider = 'internal', opened = false })
end

function Billing.NotifyBillCreated(source, bill)
    local provider = Billing.GetProvider()
    if provider == 'lb_phone' then
        local lb = providers().lb_phone or {}
        if lb.sendNotification and GetResourceState(lb.resource or 'lb-phone') == 'started' then
            pcall(function()
                TriggerEvent('lb-phone:server:sendNotification', source, {
                    title = lb.notificationTitle or 'Garage Fee Due',
                    message = lb.notificationMessage or 'You have an unpaid public garage storage fee.'
                })
            end)
        end
    end
end
