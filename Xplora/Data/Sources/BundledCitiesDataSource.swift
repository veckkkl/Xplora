//
//  BundledCitiesDataSource.swift
//  Xplora
//

import Foundation

/// Read-only bundled catalog of curated cities per place code.
/// This is the only place in the codebase that owns raw city display data;
/// all callers should go through `CitiesCatalogRepo`, never reach in here.
///
/// Each entry pairs a stable id-suffix (used for the `CatalogCity.id` and
/// the L10n key `city.<placeCode>.<suffix>`) with an English fallback name.
enum BundledCitiesDataSource {

    static let citiesByPlaceCode: [String: [CatalogCity]] = [
        "AR": cities("AR", [
            ("buenos_aires", "Buenos Aires"),
            ("patagonia", "Patagonia"),
            ("mendoza", "Mendoza"),
            ("bariloche", "Bariloche"),
            ("cordoba", "Córdoba"),
        ]),
        "AU": cities("AU", [
            ("sydney", "Sydney"),
            ("melbourne", "Melbourne"),
            ("brisbane", "Brisbane"),
            ("perth", "Perth"),
            ("cairns", "Cairns"),
        ]),
        "AT": cities("AT", [
            ("vienna", "Vienna"),
            ("salzburg", "Salzburg"),
            ("innsbruck", "Innsbruck"),
            ("graz", "Graz"),
        ]),
        "BE": cities("BE", [
            ("brussels", "Brussels"),
            ("bruges", "Bruges"),
            ("ghent", "Ghent"),
            ("antwerp", "Antwerp"),
        ]),
        "BR": cities("BR", [
            ("rio_de_janeiro", "Rio de Janeiro"),
            ("sao_paulo", "São Paulo"),
            ("salvador", "Salvador"),
            ("florianopolis", "Florianópolis"),
            ("manaus", "Manaus"),
        ]),
        "CA": cities("CA", [
            ("toronto", "Toronto"),
            ("vancouver", "Vancouver"),
            ("montreal", "Montreal"),
            ("quebec_city", "Quebec City"),
            ("banff", "Banff"),
        ]),
        "CL": cities("CL", [
            ("santiago", "Santiago"),
            ("patagonia", "Patagonia"),
            ("valparaiso", "Valparaíso"),
            ("san_pedro_de_atacama", "San Pedro de Atacama"),
        ]),
        "CN": cities("CN", [
            ("beijing", "Beijing"),
            ("shanghai", "Shanghai"),
            ("xian", "Xi'an"),
            ("chengdu", "Chengdu"),
            ("guilin", "Guilin"),
        ]),
        "CO": cities("CO", [
            ("bogota", "Bogotá"),
            ("cartagena", "Cartagena"),
            ("medellin", "Medellín"),
            ("santa_marta", "Santa Marta"),
        ]),
        "HR": cities("HR", [
            ("dubrovnik", "Dubrovnik"),
            ("split", "Split"),
            ("zagreb", "Zagreb"),
            ("hvar", "Hvar"),
            ("plitvice", "Plitvice"),
        ]),
        "CZ": cities("CZ", [
            ("prague", "Prague"),
            ("brno", "Brno"),
            ("cesky_krumlov", "Český Krumlov"),
        ]),
        "DK": cities("DK", [
            ("copenhagen", "Copenhagen"),
            ("aarhus", "Aarhus"),
            ("odense", "Odense"),
        ]),
        "EG": cities("EG", [
            ("cairo", "Cairo"),
            ("luxor", "Luxor"),
            ("aswan", "Aswan"),
            ("alexandria", "Alexandria"),
            ("sharm_el_sheikh", "Sharm el-Sheikh"),
        ]),
        "FI": cities("FI", [
            ("helsinki", "Helsinki"),
            ("rovaniemi", "Rovaniemi"),
            ("turku", "Turku"),
            ("tampere", "Tampere"),
        ]),
        "FR": cities("FR", [
            ("paris", "Paris"),
            ("normandy", "Normandy"),
            ("nice", "Nice"),
            ("lyon", "Lyon"),
            ("marseille", "Marseille"),
            ("bordeaux", "Bordeaux"),
        ]),
        "DE": cities("DE", [
            ("berlin", "Berlin"),
            ("munich", "Munich"),
            ("hamburg", "Hamburg"),
            ("frankfurt", "Frankfurt"),
            ("cologne", "Cologne"),
            ("dresden", "Dresden"),
        ]),
        "GR": cities("GR", [
            ("athens", "Athens"),
            ("santorini", "Santorini"),
            ("mykonos", "Mykonos"),
            ("thessaloniki", "Thessaloniki"),
            ("crete", "Crete"),
        ]),
        "HU": cities("HU", [
            ("budapest", "Budapest"),
            ("pecs", "Pécs"),
            ("debrecen", "Debrecen"),
            ("eger", "Eger"),
        ]),
        "IS": cities("IS", [
            ("reykjavik", "Reykjavik"),
            ("akureyri", "Akureyri"),
            ("vik", "Vík"),
            ("snaefellsnes", "Snæfellsnes"),
        ]),
        "IN": cities("IN", [
            ("delhi", "Delhi"),
            ("mumbai", "Mumbai"),
            ("jaipur", "Jaipur"),
            ("goa", "Goa"),
            ("varanasi", "Varanasi"),
            ("agra", "Agra"),
        ]),
        "ID": cities("ID", [
            ("bali", "Bali"),
            ("jakarta", "Jakarta"),
            ("lombok", "Lombok"),
            ("komodo", "Komodo"),
            ("yogyakarta", "Yogyakarta"),
        ]),
        "IE": cities("IE", [
            ("dublin", "Dublin"),
            ("galway", "Galway"),
            ("cork", "Cork"),
            ("killarney", "Killarney"),
        ]),
        "IL": cities("IL", [
            ("jerusalem", "Jerusalem"),
            ("tel_aviv", "Tel Aviv"),
            ("haifa", "Haifa"),
            ("eilat", "Eilat"),
        ]),
        "IT": cities("IT", [
            ("rome", "Rome"),
            ("florence", "Florence"),
            ("venice", "Venice"),
            ("milan", "Milan"),
            ("amalfi", "Amalfi"),
            ("sicily", "Sicily"),
        ]),
        "JP": cities("JP", [
            ("tokyo", "Tokyo"),
            ("kyoto", "Kyoto"),
            ("osaka", "Osaka"),
            ("hiroshima", "Hiroshima"),
            ("nara", "Nara"),
            ("hokkaido", "Hokkaido"),
        ]),
        "JO": cities("JO", [
            ("amman", "Amman"),
            ("petra", "Petra"),
            ("wadi_rum", "Wadi Rum"),
            ("aqaba", "Aqaba"),
        ]),
        "KE": cities("KE", [
            ("nairobi", "Nairobi"),
            ("maasai_mara", "Maasai Mara"),
            ("mombasa", "Mombasa"),
            ("lamu", "Lamu"),
        ]),
        "MX": cities("MX", [
            ("mexico_city", "Mexico City"),
            ("cancun", "Cancún"),
            ("oaxaca", "Oaxaca"),
            ("tulum", "Tulum"),
            ("guadalajara", "Guadalajara"),
        ]),
        "MA": cities("MA", [
            ("marrakech", "Marrakech"),
            ("fes", "Fes"),
            ("casablanca", "Casablanca"),
            ("chefchaouen", "Chefchaouen"),
            ("essaouira", "Essaouira"),
        ]),
        "NL": cities("NL", [
            ("amsterdam", "Amsterdam"),
            ("rotterdam", "Rotterdam"),
            ("the_hague", "The Hague"),
            ("utrecht", "Utrecht"),
        ]),
        "NZ": cities("NZ", [
            ("auckland", "Auckland"),
            ("queenstown", "Queenstown"),
            ("christchurch", "Christchurch"),
            ("wellington", "Wellington"),
        ]),
        "NO": cities("NO", [
            ("oslo", "Oslo"),
            ("bergen", "Bergen"),
            ("tromso", "Tromsø"),
            ("stavanger", "Stavanger"),
            ("lofoten", "Lofoten"),
        ]),
        "PE": cities("PE", [
            ("lima", "Lima"),
            ("cusco", "Cusco"),
            ("machu_picchu", "Machu Picchu"),
            ("arequipa", "Arequipa"),
        ]),
        "PH": cities("PH", [
            ("manila", "Manila"),
            ("palawan", "Palawan"),
            ("cebu", "Cebu"),
            ("siargao", "Siargao"),
            ("boracay", "Boracay"),
        ]),
        "PL": cities("PL", [
            ("warsaw", "Warsaw"),
            ("krakow", "Kraków"),
            ("gdansk", "Gdańsk"),
            ("wroclaw", "Wrocław"),
        ]),
        "PT": cities("PT", [
            ("lisbon", "Lisbon"),
            ("porto", "Porto"),
            ("algarve", "Algarve"),
            ("sintra", "Sintra"),
            ("madeira", "Madeira"),
        ]),
        "RO": cities("RO", [
            ("bucharest", "Bucharest"),
            ("transylvania", "Transylvania"),
            ("sibiu", "Sibiu"),
            ("cluj_napoca", "Cluj-Napoca"),
        ]),
        "RU": cities("RU", [
            ("moscow", "Moscow"),
            ("st_petersburg", "St. Petersburg"),
            ("kazan", "Kazan"),
            ("sochi", "Sochi"),
        ]),
        "SA": cities("SA", [
            ("riyadh", "Riyadh"),
            ("jeddah", "Jeddah"),
            ("alula", "AlUla"),
            ("neom", "Neom"),
        ]),
        "ZA": cities("ZA", [
            ("cape_town", "Cape Town"),
            ("johannesburg", "Johannesburg"),
            ("kruger", "Kruger"),
            ("durban", "Durban"),
        ]),
        "KR": cities("KR", [
            ("seoul", "Seoul"),
            ("busan", "Busan"),
            ("jeju", "Jeju"),
            ("gyeongju", "Gyeongju"),
        ]),
        "ES": cities("ES", [
            ("madrid", "Madrid"),
            ("barcelona", "Barcelona"),
            ("seville", "Seville"),
            ("granada", "Granada"),
            ("valencia", "Valencia"),
        ]),
        "SE": cities("SE", [
            ("stockholm", "Stockholm"),
            ("gothenburg", "Gothenburg"),
            ("malmo", "Malmö"),
            ("uppsala", "Uppsala"),
        ]),
        "CH": cities("CH", [
            ("zurich", "Zurich"),
            ("geneva", "Geneva"),
            ("bern", "Bern"),
            ("interlaken", "Interlaken"),
            ("lucerne", "Lucerne"),
        ]),
        "TH": cities("TH", [
            ("bangkok", "Bangkok"),
            ("chiang_mai", "Chiang Mai"),
            ("phuket", "Phuket"),
            ("koh_samui", "Koh Samui"),
        ]),
        "TR": cities("TR", [
            ("istanbul", "Istanbul"),
            ("cappadocia", "Cappadocia"),
            ("antalya", "Antalya"),
            ("bodrum", "Bodrum"),
        ]),
        "UA": cities("UA", [
            ("kyiv", "Kyiv"),
            ("lviv", "Lviv"),
            ("odesa", "Odesa"),
        ]),
        "GB": cities("GB", [
            ("london", "London"),
            ("edinburgh", "Edinburgh"),
            ("oxford", "Oxford"),
            ("manchester", "Manchester"),
            ("bath", "Bath"),
        ]),
        "US": cities("US", [
            ("new_york", "New York"),
            ("los_angeles", "Los Angeles"),
            ("san_francisco", "San Francisco"),
            ("chicago", "Chicago"),
            ("new_orleans", "New Orleans"),
        ]),
        "VN": cities("VN", [
            ("hanoi", "Hanoi"),
            ("ho_chi_minh_city", "Ho Chi Minh City"),
            ("hoi_an", "Hội An"),
            ("da_nang", "Da Nang"),
        ]),
    ]

    // MARK: - Helpers

    private static func cities(_ placeCode: String, _ entries: [(String, String)]) -> [CatalogCity] {
        entries.map { suffix, fallback in
            CatalogCity(
                id: "\(placeCode)-\(suffix)",
                nameKey: "city.\(placeCode).\(suffix)",
                fallbackName: fallback,
                placeCode: placeCode
            )
        }
    }
}
