define ->
    # The API endpoint versions required by this version
    # of the codebase are configured here.
    SERVICEMAP_BACKEND_BASE: appSettings.service_map_backend + '/v2'
    LINKEDEVENTS_BACKEND_BASE: appSettings.linkedevents_backend + '/v1'
    RESPA_BACKEND_BASE: appSettings.respa_backend + '/v1'
    OPEN311_BACKEND_BASE: appSettings.open311_backend + '/v1'
    OPEN311_WRITE_BACKEND_BASE: appSettings.open311_write_backend + '/'
    OPENTRIPPLANNER_BACKEND_BASE: appSettings.otp_backend + '/v1' + '/routers/hsl/index/graphql'
