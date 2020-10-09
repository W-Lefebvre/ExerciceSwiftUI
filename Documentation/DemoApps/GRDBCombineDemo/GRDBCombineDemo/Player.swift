import GRDB

/// The Player struct.
///
/// Identifiable conformance supports SwiftUI list animations
struct Player: Identifiable {
    /// The player id.
    ///
    /// Int64 is the recommended type for auto-incremented database ids.
    /// Use nil for players that are not inserted yet in the database.
    var id: Int64?
    var name: String
    var score: Int
    var teamId: Int64?
}

extension Player: TableRecord {
    private static let names = [
        "Arthur", "Anita", "Barbara", "Bernard", "Craig", "Chiara", "David",
        "Dean", "Éric", "Elena", "Fatima", "Frederik", "Gilbert", "Georgette",
        "Henriette", "Hassan", "Ignacio", "Irene", "Julie", "Jack", "Karl",
        "Kristel", "Louis", "Liz", "Masashi", "Mary", "Noam", "Nicole",
        "Ophelie", "Oleg", "Pascal", "Patricia", "Quentin", "Quinn", "Raoul",
        "Rachel", "Stephan", "Susie", "Tristan", "Tatiana", "Ursule", "Urbain",
        "Victor", "Violette", "Wilfried", "Wilhelmina", "Yvon", "Yann",
        "Zazie", "Zoé"]
    
    static let team = belongsTo(Team.self)
    
    /// Creates a new player with empty name and zero score
    static func new() -> Player {
        Player(id: nil, name: "", score: 0, teamId: nil)
    }
    
    /// Creates a new player with random name and random score
    static func newRandom() -> Player {
        Player(id: nil, name: randomName(), score: randomScore(), teamId: nil)
    }
    
    /// Returns a random name
    static func randomName() -> String {
        names.randomElement()!
    }
    
    /// Returns a random score
    static func randomScore() -> Int {
        10 * Int.random(in: 0...100)
    }
}

struct Team: Identifiable {
    var id: Int64?
    var teamName: String
    var teamDate: String
}

extension Team: TableRecord   {
    private static let teamNames = [
        "Rome", "Berlin", "Bruxelles", "Gand", "Madrid", "Barcelone", "Pescara",
        "Mons", "London", "Paris", "Dublin", "Nantes", "Lille", "Marseille",
        "Casablanca", "Bruges", "Turin", "Milan", "Maastricht", "Amsterdam", "Liège",
        "Courtrai", "Manchester", "Arsenal", "Perth", "Sydney", "Melbourne", "Victoria",
        "Los Angeles", "New-York", "Californie", "Washington", "Metz", "La Louvière", "Maasmechelen",
        "Mexico", "Tokyo", "Moscou", "Bangkok", "Geneve", "Mykonos", "Anvers",
        "Fes", "Charleroi", "Chelsea", "Totthenam", "Hollywood", "Brest",
        "Montpellier", "Cannes"]
    
    static func newTeam() -> Team {
        Team(id: nil, teamName: "", teamDate: "")
    }
    /// Returns a random team name
    static func randomTeamName() -> String {
        teamNames.randomElement()!
    }
    
    static func newRandomTeam() -> Team {
        Team(id: nil, teamName: "", teamDate: "")
    }
}

struct PlayerInfo: FetchableRecord, Decodable {
    let player: Player
    let team: Team
}

extension PlayerInfo: TableRecord {
    
}
// MARK: - Persistence

/// Make Player a Codable Record.
///
/// See https://github.com/groue/GRDB.swift/blob/master/README.md#records
extension Player: Codable, FetchableRecord, MutablePersistableRecord {
    // Define database columns from CodingKeys
    fileprivate enum Columns {
        static let name = Column(CodingKeys.name)
        static let score = Column(CodingKeys.score)
    }
    
    /// Updates a player id after it has been inserted in the database.
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

extension Team: Codable, FetchableRecord, MutablePersistableRecord {
    // Define database columns from CodingKeys
    fileprivate enum Columns {
        static let teamName = Column(CodingKeys.teamName)
        static let teamDate = Column(CodingKeys.teamDate)
    }
    
    /// Updates a player id after it has been inserted in the database.
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
// MARK: - Player Database Requests

/// Define some player requests used by the application.
///
/// See https://github.com/groue/GRDB.swift/blob/master/README.md#requests
/// See https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md
extension DerivableRequest where RowDecoder == Player {
    /// A request of players ordered by name
    ///
    /// For example:
    ///
    ///     let players = try dbQueue.read { db in
    ///         try Player.all().orderedByName().fetchAll(db)
    ///     }
    func orderedByName() -> Self {
        order(Player.Columns.name)
    }
    
    /// A request of players ordered by score
    ///
    /// For example:
    ///
    ///     let players = try dbQueue.read { db in
    ///         try Player.all().orderedByScore().fetchAll(db)
    ///     }
    func orderedByScore() -> Self {
        order(Player.Columns.score.desc, Player.Columns.name)
    }
    
    func orderedByTeamName() -> Self {
        order(Team.Columns.teamName)
    }
}

extension DerivableRequest where RowDecoder == Team {
    func orderedByTeamName() -> Self {
        order(Team.Columns.teamName)
    }
}
