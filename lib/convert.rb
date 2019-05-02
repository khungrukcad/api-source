def convert(version, endpoint, json)
    if version == 1
        old_json = Marshal.load(Marshal.dump(json))
        old_json["pools"].each { |p|
            p["name"] = ""
            p["num"] = p["num"].to_s unless p["num"].nil?
            p["free"] = (p["category"] == "free") unless p["category"].nil?
            p.delete("category")
            p.delete("presets")
            p.delete("resolved")
        }
        return old_json
    end

    # version 2
    pools = json["pools"]

    categories = {
        default: {
            groups: {}
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
        category = categories[category_name] || {groups: {}}

        # pick first
        if p.key?("presets")
            category["presets"] = p["presets"]
            p.delete("presets")
        end

        group_key = p["country"].clone
        if p.key?("area")
            group_key << ".#{p['area']}"
        end

        groups = category[:groups]
        group = groups[group_key]
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

        if p["resolved"].nil? && p["resolved"]
            p.delete("hostname")
        elsif externalHostname
            p.delete("hostname")
        end

        pools << p
        group["pools"] = pools
        groups[group_key] = group
        category[:groups] = groups

        categories[category_name] = category
    }

    categories_linear = []
    categories.each { |k, v|
        if k == :default
            k = ""
        end
        obj = {
            name: k,
            groups: v[:groups].values
        }
        if v.key?("presets")
            obj["presets"] = v["presets"]
        end
        categories_linear << obj
    }

    json.delete("pools")
    json["categories"] = categories_linear
    return json
end
