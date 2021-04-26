class Dog

    #has a name and a breed
    attr_accessor :id, :name, :breed

    #has an id that defaults to `nil` on initialization
    #accepts key value pairs as arguments to initialize
    def initialize(id: nil, name:, breed:)
        @id = id
        @name = name
        @breed = breed
    end

    #creates the dogs table in the database
    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
        )
        SQL

        DB[:conn].execute(sql)
    end

    #drops the dogs table from the database
    #saves an instance of the dog class to the database and then sets the given dogs `id` attribute
    def self.drop_table
        sql = <<-SQL
        DROP TABLE IF EXISTS dogs
        SQL

        DB[:conn].execute(sql)
    end

    #returns an instance of the dog class
    def save
        if self.id
            self.update
        else
            sql = <<-SQL
            INSERT INTO dogs (name, breed) VALUES (?, ?)
            SQL

            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    #takes in a hash of attributes and uses metaprogramming to create a new dog object. Then it uses the #save method to save that dog to the database
    #returns a new dog object

    def self.create(name)
        dog = self.new(name)
        dog.save
        dog
    end

    #creates an instance with corresponding attribute values
    def self.new_from_db(row)
        new_dog = self.new(name: row[1], breed: row[2])
        new_dog.id = row[0]
        new_dog.name = row[1]
        new_dog.breed = row[2]
        new_dog
    end

    #returns a new dog object by id
    def self.find_by_id(id)
        sql = <<-SQL
        SELECT * FROM dogs WHERE id = ?
        SQL

        result = DB[:conn].execute(sql, id).flatten
        Dog.new(id: result[0], name: result[1], breed: result[2])
    end

    #creates an instance of a dog if it does not already exist
    #when two dogs have the same name and different breed, it returns the correct dog
    #when creating a new dog with the same name as persisted dogs, it returns the correct dog
    def self.find_or_create_by(name:, breed:)
        sql = <<-SQL
        SELECT * FROM dogs WHERE NAME = ? AND breed = ?
        SQL

        dog = DB[:conn].execute(sql, name, breed)
        if !dog.empty?
            dog_data = dog[0]
            dog = self.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2])
        else
            dog = self.create(name: name, breed: breed)
        end
        dog
    end

    #returns an instance of dog that matches the name from the DB
    def self.find_by_name(name)
        sql = <<-SQL
        SELECT * FROM dogs WHERE name = ?
        SQL
        # binding.pry

        result = DB[:conn].execute(sql, name).flatten
        self.new(id: result[0], name: result[1], breed: result[2])
    end

    #updates the record associated with a given instance
    def update
        sql = <<-SQL
        UPDATE dogs SET name = ?, breed = ? WHERE id = ?
        SQL

        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

end