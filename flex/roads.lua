local roads = osm2pgsql.define_way_table('roads', {
    { column = 'osm_id', type = 'bigint', not_null = true },

    { column = 'highway', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'ref', type = 'text' },

    { column = 'maxspeed', type = 'text' },
    { column = 'maxspeed_forward', type = 'text' },
    { column = 'maxspeed_backward', type = 'text' },
    { column = 'maxspeed_type', type = 'text' },

    { column = 'oneway', type = 'boolean' },

    { column = 'lanes', type = 'smallint' },
    { column = 'layer', type = 'smallint' },

    { column = 'bridge', type = 'boolean' },
    { column = 'tunnel', type = 'boolean' },

    { column = 'surface', type = 'text' },
    { column = 'junction', type = 'text' },
    { column = 'access', type = 'text' },

    { column = 'geom', type = 'linestring', projection = 4326, not_null = true }
})

local allowed = {
    motorway = true,
    motorway_link = true,

    trunk = true,
    trunk_link = true,

    primary = true,
    primary_link = true,

    secondary = true,
    secondary_link = true,

    tertiary = true,
    tertiary_link = true,

    residential = true,
    unclassified = true,

    service = true,
    living_street = true,
    road = true
}

local function to_bool(v)
    if not v then
        return nil
    end

    return v == 'yes'
end

local function to_int(v)
    if not v then
        return nil
    end

    local n = tonumber(v)
    return n
end

function osm2pgsql.process_way(object)

    local highway = object.tags.highway

    if not highway or not allowed[highway] then
        return
    end

    roads:insert({

        osm_id = object.id,

        highway = highway,

        name = object.tags.name,

        ref = object.tags.ref,

        maxspeed = object.tags.maxspeed,

        maxspeed_forward = object.tags["maxspeed:forward"],

        maxspeed_backward = object.tags["maxspeed:backward"],

        maxspeed_type = object.tags["maxspeed:type"],

        oneway = to_bool(object.tags.oneway),

        lanes = to_int(object.tags.lanes),

        layer = to_int(object.tags.layer),

        bridge = to_bool(object.tags.bridge),

        tunnel = to_bool(object.tags.tunnel),

        surface = object.tags.surface,

        junction = object.tags.junction,

        access = object.tags.access,

        geom = object:as_linestring()

    })

end
