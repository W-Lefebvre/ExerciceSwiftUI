import Combine
import GRDB

/// AppDatabase lets the application access the database.
///
/// It applies the pratices recommended at
/// https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md
struct AppDatabase {
    private let dbWriter: DatabaseWriter
    
    /// Creates an AppDatabase and make sure the database schema is ready.
    init(_ dbWriter: DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    /// The DatabaseMigrator that defines the database schema.
    ///
    /// See https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        // Speed up development by nuking the database when migrations change
        // See https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md#the-erasedatabaseonschemachange-option
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        migrator.registerMigration("createPlayer") { db in
            // Create a table
            // See https://github.com/groue/GRDB.swift#create-tables
            try db.create(table: "player") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("teamName", .text).notNull()
                    // Sort player names in a localized case insensitive fashion by default
                    // See https://github.com/groue/GRDB.swift/blob/master/README.md#unicode
                    .collate(.localizedCaseInsensitiveCompare)
                t.column("score", .integer).notNull()
            }
        }
        
        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }
        
        return migrator
    }
}

// MARK: - Database Access
//
// This extension defines methods that fulfill application needs, both in terms
// of writes and reads.
extension AppDatabase {
    // MARK: Writes
    
    /// Save (insert or update) a player.
    func savePlayer(_ player: inout Player) throws {
        try dbWriter.write { db in
            try player.save(db)
        }
    }
    
    /// Delete the specified players
    func deletePlayers(ids: [Int64]) throws {
        try dbWriter.write { db in
            _ = try Player.deleteAll(db, keys: ids)
        }
    }
    
    /// Delete all players
    func deleteAllPlayers() throws {
        try dbWriter.write { db in
            _ = try Player.deleteAll(db)
        }
    }
    
    /// Refresh all players (by performing some random changes, for demo purpose).
    func refreshPlayers() throws {
        try dbWriter.write { db in
            if try Player.fetchCount(db) == 0 {
                // Insert new random players
                try createRandomPlayers(db)
            } else {
                // Insert a player
                if Bool.random() {
                    var player = Player.newRandom()
                    try player.insert(db)
                }
                // Delete a random player
                if Bool.random() {
                    try Player.order(sql: "RANDOM()").limit(1).deleteAll(db)
                }
                // Update some players
                for var player in try Player.fetchAll(db) where Bool.random() {
                    try player.updateChanges(db) {
                        $0.score = Player.randomScore()
                        $0.teamName = Player.randomTeamName()
                    }
                }
            }
        }
    }
    
    /// Create random players if the database is empty.
    func createRandomPlayersIfEmpty() throws {
        try dbWriter.write { db in
            if try Player.fetchCount(db) == 0 {
                try createRandomPlayers(db)
            }
        }
    }
    
    func createRandomTeamsIfEmpty() throws {
        try dbWriter.write { db in
            if try Player.fetchCount(db) == 0 {
                try createRandomTeams(db)
            }
        }
    }
    
    /// Support for `createRandomPlayersIfEmpty()` and `refreshPlayers()`.
    private func createRandomPlayers(_ db: Database) throws {
        for _ in 0..<8 {
            var player = Player.newRandom()
            try player.insert(db)
        }
    }
    
    private func createRandomTeams(_ db: Database) throws {
        for _ in 0..<8 {
            var player = Player.newRandom()
            try player.insert(db)
        }
    }
    
    // MARK: Reads
    
    /// Returns a publisher that tracks changes in players ordered by name
    func playersOrderedByNamePublisher() -> AnyPublisher<[Player], Error> {
        ValueObservation
            .tracking(Player.all().orderedByName().fetchAll)
            .publisher(in: dbWriter)
            .eraseToAnyPublisher()
    }
    
    /// Returns a publisher that tracks changes in players ordered by teams
    func playersOrderedByTeamNamePublisher() -> AnyPublisher<[Player], Error> {
        ValueObservation
            .tracking(Player.all().orderedByTeamName().fetchAll)
            .publisher(in: dbWriter)
            .eraseToAnyPublisher()
    }
    
    /// Returns a publisher that tracks changes in players ordered by score
    func playersOrderedByScorePublisher() -> AnyPublisher<[Player], Error> {
        ValueObservation
            .tracking(Player.all().orderedByScore().fetchAll)
            .publisher(in: dbWriter)
            .eraseToAnyPublisher()
    }
}
