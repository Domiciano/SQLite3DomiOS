//
//  DatabaseHandler.swift
//  iOS1FirebaseIntegration
//
//  Created by Domiciano Rincón on 11/06/20.
//  Copyright © 2020 Domiciano Rincón. All rights reserved.
//

import Foundation
import SQLite3


public class DatabaseHandler{
    
    public static var instance : DatabaseHandler? = nil
    private var dbname:String?
    private var version:Int?
    
    
    
    public static func getInstance() -> DatabaseHandler{
        if(instance == nil){
            instance = DatabaseHandler();
        }
        return instance!;
    }
    
    public func selectDatabase(dbname:String, version:Int){
        self.dbname = dbname;
        self.version = version;
    }
    
    private init(){}
    
    //Globales del objeto
    
    public func initialize(){
        verifyDBVersion()
    }
    
    private func verifyDBVersion(){
        guard let version = self.version else {
            print("Version is undefined")
            return
        }
        create(sql: "CREATE TABLE IF NOT EXISTS db_version(id INTEGER PRIMARY KEY)")
        let cursor = query(sql: "SELECT * FROM db_version WHERE id = (SELECT MAX(id) FROM db_version)")
        guard let results = cursor else {return}
        if results.next(){
            let lastversion = results.getIntAt(column: 0)
            if version == lastversion {
                print(">>>SQLite You have opened successfully the database at version \(version)")
            }else if version>lastversion{
                onDatabaseUpdate()
                create(sql: "INSERT OR IGNORE INTO db_version(id) VALUES (\(version))")
                print(">>>SQLite The version has been updated to version \(version)")
            }else {
                print(">>>SQLite Important warning! the version you try to access is no longer available. Current version is \(lastversion)")
            }
        }else{
            internalExecute(sql: "INSERT OR IGNORE INTO db_version(id) VALUES (\(version))")
        }
    }
    
    private func onDatabaseUpdate(){
        let cursor = query(sql: "SELECT * FROM sqlite_master WHERE type='table'")
        guard let results = cursor else {return}
        while(results.next()){
            let tablename = results.getStringAt(column: 1)
            if tablename == "sqlite_sequence"{
                continue
            }
            if tablename == "db_version"{
                continue
            }
            create(sql: "DROP TABLE '\(tablename)'")
            print(">>>SQLite Table \(tablename) updated to new version")
        }
        
    }
    
    private func openDatabase() -> OpaquePointer?{
        guard let dbname = self.dbname else {
            print("dbname is undefined")
            return nil
        }
        let fileURL = try! FileManager
        .default
        .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create:true)
            .appendingPathComponent(dbname)
        
        var db: OpaquePointer?
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            return db
        } else {
            print("Unable to open database.")
            return nil
        }
    }
    
    
    
    
    
    public func create(sql:String){
        guard let db = openDatabase() else{
            print("SQLite error: can't open connection with SQLite")
            return
        }
        
        var sqlStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &sqlStatement, nil) == SQLITE_OK {
          if sqlite3_step(sqlStatement) == SQLITE_DONE {}
          else {
            print(">>>SQLite error at execute SQL: \(sql) >>> \(String(cString: sqlite3_errmsg(db)))")
          }
          sqlite3_finalize(sqlStatement)
        } else {
          let errorMessage = String(cString: sqlite3_errmsg(db))
          print(">>>SQLite error: \(sql) >>> \(errorMessage)")
        }
        sqlite3_close(db)
    }
    
    private func internalExecute(sql:String){
        guard let db = openDatabase() else{
            print("SQLite error: can't open connection with SQLite")
            return
        }
        var sqlStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &sqlStatement, nil) == SQLITE_OK {
          if sqlite3_step(sqlStatement) == SQLITE_DONE {}
          else {
            print(">>>SQLite error at execute SQL: \(sql) >>> \(String(cString: sqlite3_errmsg(db)))")
          }
          sqlite3_finalize(sqlStatement)
        } else {
          let errorMessage = String(cString: sqlite3_errmsg(db))
          print(">>>SQLite error: \(sql) >>> \(errorMessage)")
        }
        sqlite3_close(db)
    }
    
    public func execute(sql:String){
        guard let db = openDatabase() else{
            print("SQLite error: can't open connection with SQLite")
            return
        }
        var sqlStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &sqlStatement, nil) == SQLITE_OK {
          if sqlite3_step(sqlStatement) == SQLITE_DONE {
            print(">>>SQLite OK: \(sql)")
          } else {
            print(">>>SQLite error at execute SQL: \(sql) >>> \(String(cString: sqlite3_errmsg(db)))")
          }
          sqlite3_finalize(sqlStatement)
        } else {
          let errorMessage = String(cString: sqlite3_errmsg(db))
          print(">>>SQLite error: \(sql) >>> \(errorMessage)")
        }
        sqlite3_close(db)
    }
    
    public func query(sql:String) -> ResultSet?{
        guard let db = openDatabase() else{
            print("SQLite error: can't open connection with SQLite")
            return ResultSet(data: [[String]]())
        }
        var cursor:ResultSet? = nil
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &queryStatement, nil) == SQLITE_OK {
          let columnNumber = sqlite3_column_count(queryStatement)
          var data : [[String]] = []
          while (sqlite3_step(queryStatement) == SQLITE_ROW) {
            var row:[String] = []
            for i in 0..<columnNumber{
                let chunk = String(cString: sqlite3_column_text(queryStatement, i))
                row.append(chunk)
            }
            data.append(row)
          }
            if data.count == 0 {
                print(">>>SQLite Query returns 0 results")
            }
          cursor = ResultSet(data: data)
          sqlite3_finalize(queryStatement)
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print(">>>SQLite Query didn't excuted: \(sql) >>> \(errorMessage)")
        }
        sqlite3_close(db)
        return cursor
    }
    
    //UNDER CONSTRUCTION--------------------->
    
    //DONE
    private func createTable<T>(entityClass:T) {
        let tableName:String = String(describing: T.self)
        let fields:[String] = Mirror(reflecting: entityClass).children.compactMap { $0.label }
        if fields.count == 0{
            print("La clase modelo está mal formada")
            return
        }
        var sql = "CREATE TABLE IF NOT EXISTS \(tableName)(_id INTEGER PRIMARY KEY AUTOINCREMENT,\(fields[0]) VARCHAR"
        for index in 1..<fields.count{
            sql += ",\(fields[index]) VARCHAR"
        }
        sql += ")"
        print(sql)
        execute(sql: sql)
    }
    
    //DONE
    private func insertToDatabase<T>(object:T){
        let tableName:String = String(describing: T.self)
        let fields:[String] = Mirror(reflecting: object).children.compactMap { $0.label }
        let valuesRaw:[Any] = Mirror(reflecting: object).children.compactMap { $0.value }
        var values:[String] = []
        for opString in valuesRaw{
            values.append(opString as! String)
        }
        
        if fields.count == 0{
            print("La clase modelo está mal formada")
            return
        }
        
        var sql = "INSERT INTO \(tableName)(\(fields[0])"
        for index in 1..<fields.count{
            sql += ",\(fields[index])"
        }
        
        sql += ") VALUES ('\(values[0])'"
        for index in 1..<values.count{
            sql += ",'\(values[index])'"
        }
        sql += ")"
        print(sql)
        execute(sql: sql)
    }

}
