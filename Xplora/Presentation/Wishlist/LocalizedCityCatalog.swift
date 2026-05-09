// LocalizedCityCatalog.swift
// Xplora

import Foundation

enum LocalizedCityCatalog {
    static let cities: [String: [CitySuggestion]] = [
        "AR": make("AR", ["buenos_aires", "patagonia", "mendoza", "bariloche", "cordoba"]),
        "AU": make("AU", ["sydney", "melbourne", "brisbane", "perth", "cairns"]),
        "AT": make("AT", ["vienna", "salzburg", "innsbruck", "graz"]),
        "BE": make("BE", ["brussels", "bruges", "ghent", "antwerp"]),
        "BR": make("BR", ["rio_de_janeiro", "sao_paulo", "salvador", "florianopolis", "manaus"]),
        "CA": make("CA", ["toronto", "vancouver", "montreal", "quebec_city", "banff"]),
        "CL": make("CL", ["santiago", "patagonia", "valparaiso", "san_pedro_de_atacama"]),
        "CN": make("CN", ["beijing", "shanghai", "xian", "chengdu", "guilin"]),
        "CO": make("CO", ["bogota", "cartagena", "medellin", "santa_marta"]),
        "HR": make("HR", ["dubrovnik", "split", "zagreb", "hvar", "plitvice"]),
        "CZ": make("CZ", ["prague", "brno", "cesky_krumlov"]),
        "DK": make("DK", ["copenhagen", "aarhus", "odense"]),
        "EG": make("EG", ["cairo", "luxor", "aswan", "alexandria", "sharm_el_sheikh"]),
        "FI": make("FI", ["helsinki", "rovaniemi", "turku", "tampere"]),
        "FR": make("FR", ["paris", "normandy", "nice", "lyon", "marseille", "bordeaux"]),
        "DE": make("DE", ["berlin", "munich", "hamburg", "frankfurt", "cologne", "dresden"]),
        "GR": make("GR", ["athens", "santorini", "mykonos", "thessaloniki", "crete"]),
        "HU": make("HU", ["budapest", "pecs", "debrecen", "eger"]),
        "IS": make("IS", ["reykjavik", "akureyri", "vik", "snaefellsnes"]),
        "IN": make("IN", ["delhi", "mumbai", "jaipur", "goa", "varanasi", "agra"]),
        "ID": make("ID", ["bali", "jakarta", "lombok", "komodo", "yogyakarta"]),
        "IE": make("IE", ["dublin", "galway", "cork", "killarney"]),
        "IL": make("IL", ["jerusalem", "tel_aviv", "haifa", "eilat"]),
        "IT": make("IT", ["rome", "florence", "venice", "milan", "amalfi", "sicily"]),
        "JP": make("JP", ["tokyo", "kyoto", "osaka", "hiroshima", "nara", "hokkaido"]),
        "JO": make("JO", ["amman", "petra", "wadi_rum", "aqaba"]),
        "KE": make("KE", ["nairobi", "maasai_mara", "mombasa", "lamu"]),
        "MX": make("MX", ["mexico_city", "cancun", "oaxaca", "tulum", "guadalajara"]),
        "MA": make("MA", ["marrakech", "fes", "casablanca", "chefchaouen", "essaouira"]),
        "NL": make("NL", ["amsterdam", "rotterdam", "the_hague", "utrecht"]),
        "NZ": make("NZ", ["auckland", "queenstown", "christchurch", "wellington"]),
        "NO": make("NO", ["oslo", "bergen", "tromso", "stavanger", "lofoten"]),
        "PE": make("PE", ["lima", "cusco", "machu_picchu", "arequipa"]),
        "PH": make("PH", ["manila", "palawan", "cebu", "siargao", "boracay"]),
        "PL": make("PL", ["warsaw", "krakow", "gdansk", "wroclaw"]),
        "PT": make("PT", ["lisbon", "porto", "algarve", "sintra", "madeira"]),
        "RO": make("RO", ["bucharest", "transylvania", "sibiu", "cluj_napoca"]),
        "RU": make("RU", ["moscow", "st_petersburg", "kazan", "sochi"]),
        "SA": make("SA", ["riyadh", "jeddah", "alula", "neom"]),
        "ZA": make("ZA", ["cape_town", "johannesburg", "kruger", "durban"]),
        "KR": make("KR", ["seoul", "busan", "jeju", "gyeongju"]),
        "ES": make("ES", ["madrid", "barcelona", "seville", "granada", "valencia"]),
        "SE": make("SE", ["stockholm", "gothenburg", "malmo", "uppsala"]),
        "CH": make("CH", ["zurich", "geneva", "bern", "interlaken", "lucerne"]),
        "TH": make("TH", ["bangkok", "chiang_mai", "phuket", "koh_samui"]),
        "TR": make("TR", ["istanbul", "cappadocia", "antalya", "bodrum"]),
        "UA": make("UA", ["kyiv", "lviv", "odesa"]),
        "GB": make("GB", ["london", "edinburgh", "oxford", "manchester", "bath"]),
        "US": make("US", ["new_york", "los_angeles", "san_francisco", "chicago", "new_orleans"]),
        "VN": make("VN", ["hanoi", "ho_chi_minh_city", "hoi_an", "da_nang"]),
    ]

    private static func make(_ code: String, _ ids: [String]) -> [CitySuggestion] {
        ids.map { CitySuggestion(key: "city.\(code).\($0)", countryCode: code) }
    }
}
