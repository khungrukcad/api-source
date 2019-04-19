def convert(version, endpoint, json)
    return json if version == 1

    # version 2
    pools = json["pools"]

    categories = {
        "default": {
            #"country.area": {
            #   "country": "US",
            #   "pools": []
            #}
        }
    }

    pools.each { |p|
        category_name = p["category"] || "default"
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

        p.delete("country")
        p.delete("area")

        pools << p

        group["pools"] = pools
        category[group_key] = group
        categories[category_name] = category
    }

    return categories
end
