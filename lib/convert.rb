def convert(version, endpoint, json)
    if version == 1
        json["pools"].each { |p|
            p["name"] = "" # XXX: legacy non-optional
        }
        return json
    end

    # version 2
    pools = json["pools"]

    categories = {
        default: {
            #"country.area": {
            #   "country": "US",
            #   "pools": []
            #}
        }
    }

    externalHostname = true
    json["presets"].each { |p|
        external = p["external"]
        if external.nil? || !external.key?("hostname")
            externalHostname = false
            break
        end
    }

    pools.each { |p|
        category_name = p["category"] || :default
        category = categories[category_name] || {}

        group_key = p["country"].clone
        if p.key?("area")
            group_key << ".#{p['area']}"
        end

        group = category[group_key]
        if group.nil?
            group = {
                "country": p["country"],
            }
            if p.key?("area")
                group["area"] = p["area"]
            end
            pools = []
        else
            pools = group["pools"]
        end

        p.delete("category")
        #p.delete("country")
        #p.delete("area")
        p.delete("name")

        if externalHostname
            p.delete("hostname")
        end

        pools << p

        group["pools"] = pools
        category[group_key] = group
        categories[category_name] = category
    }

    categories_linear = []
    categories.each { |k, v|
        obj = {
            name: k,
            groups: v
        }
        categories_linear << obj
    }

    json.delete("pools")
    json["categories"] = categories_linear
    return json
end
