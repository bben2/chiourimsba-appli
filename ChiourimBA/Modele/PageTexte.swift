import Foundation

struct PageTexte: Codable, Equatable, Sendable {
    var ref: String
    var titre: String
    var resume: String?
    var segments: [Segment]
    var schemas: [SchemaTexte]

    enum CodingKeys: String, CodingKey {
        case ref, titre, resume, segments, schemas
    }

    init(ref: String, titre: String, resume: String?, segments: [Segment], schemas: [SchemaTexte]) {
        self.ref = ref
        self.titre = titre
        self.resume = resume
        self.segments = segments
        self.schemas = schemas
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ref = try c.decodeIfPresent(String.self, forKey: .ref) ?? ""
        titre = try c.decodeIfPresent(String.self, forKey: .titre) ?? ""
        resume = try c.decodeIfPresent(String.self, forKey: .resume)
        segments = try c.decodeIfPresent([Segment].self, forKey: .segments) ?? []
        schemas = try c.decodeIfPresent([SchemaTexte].self, forKey: .schemas) ?? []
    }
}

struct Segment: Codable, Equatable, Sendable {
    var he: String
    var fr: String
    var rashi: [Glose]
    var tosafot: [Glose]
    var roch: [Glose]
    var explication: String?
    var schema: SchemaTexte?

    enum CodingKeys: String, CodingKey {
        case he, fr, rashi, tosafot, roch, explication, schema
    }

    init(he: String, fr: String, rashi: [Glose] = [], tosafot: [Glose] = [], roch: [Glose] = [], explication: String? = nil, schema: SchemaTexte? = nil) {
        self.he = he
        self.fr = fr
        self.rashi = rashi
        self.tosafot = tosafot
        self.roch = roch
        self.explication = explication
        self.schema = schema
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        he = try c.decodeIfPresent(String.self, forKey: .he) ?? ""
        fr = try c.decodeIfPresent(String.self, forKey: .fr) ?? ""
        rashi = try c.decodeIfPresent([Glose].self, forKey: .rashi) ?? []
        tosafot = try c.decodeIfPresent([Glose].self, forKey: .tosafot) ?? []
        roch = try c.decodeIfPresent([Glose].self, forKey: .roch) ?? []
        explication = try c.decodeIfPresent(String.self, forKey: .explication)
        schema = try c.decodeIfPresent(SchemaTexte.self, forKey: .schema)
    }
}

struct Glose: Codable, Equatable, Sendable {
    var dh: String?
    var he: String?
    var fr: String?

    enum CodingKeys: String, CodingKey {
        case dh, he, fr, titre
    }

    init(dh: String? = nil, he: String? = nil, fr: String? = nil) {
        self.dh = dh
        self.he = he
        self.fr = fr
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let mot = try c.decodeIfPresent(String.self, forKey: .dh)
        let titre = try c.decodeIfPresent(String.self, forKey: .titre)
        dh = mot ?? titre
        he = try c.decodeIfPresent(String.self, forKey: .he)
        fr = try c.decodeIfPresent(String.self, forKey: .fr)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(dh, forKey: .dh)
        try c.encodeIfPresent(he, forKey: .he)
        try c.encodeIfPresent(fr, forKey: .fr)
    }
}

struct SchemaTexte: Codable, Equatable, Sendable {
    var svg: String
    var legende: String?
}

enum ErreurDonnees: Error, Equatable, Sendable {
    case reseau
    case absent
    case illisible
    case chemin

    var message: String {
        switch self {
        case .reseau:
            return "La connexion a été interrompue. Réessayez dans un instant."
        case .absent:
            return "Cette page n'a pas encore été téléchargée."
        case .illisible:
            return "Ce texte n'a pas pu être lu."
        case .chemin:
            return "Le chemin demandé n'est pas valide."
        }
    }
}
