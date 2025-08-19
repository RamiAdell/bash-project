# 🗄️ Bash DBMS - Database Management System

A comprehensive Database Management System built entirely in Bash scripting that demonstrates how modern databases work internally using file system operations for data storage and management.

## 🚀 Features

### 📊 Database Operations (CLI)
- Create new databases
- List all existing databases
- Connect to specific databases
- Drop databases with confirmation

### 🗂️ Table Management (CLI)
- Create tables with custom schema
- Define column types and constraints
- Set primary keys with uniqueness validation
- List all tables in a database
- Drop tables safely

### 📝 Data Operations
**CLI Operations:**
- Interactive menu-driven data insertion
- Table browsing and display

**SQL Query Support:**
- `INSERT` - Add new records with validation
- `SELECT` - Query data with filtering conditions
- `UPDATE` - Modify records (single or batch operations)  
- `DELETE` - Remove records with condition matching
- `USE` - Switch between databases

### 🔧 Technical Features
- **Data Types**: `int`, `float`, `string`, `character`, `email`
- **Base64 Encoding/Decoding** for secure data storage
- **Primary Key Constraints** with duplicate prevention
- ** Atomic Transaction-like Operations** using temporary files
- **Dual Interfaces**: Menu-driven CLI and SQL command interface
- **Data Validation** and integrity checks
- **Schema Management** with metadata files

### Installation

1. Clone the repository

2. Make scripts executable:
```bash
chmod +x *.sh
```

3. Run the application:
```bash
./dbms-main.sh
```

## 📖 Usage Examples

### CLI Operations
```bash
# Start the application
./dbms-main.sh

# Use menu to:
# 1. Create Database -> company
# 2. Connect to Database -> company  
# 3. Create Table -> employees (id:int:pk, name:string, email:email)
# 4. Insert data via interactive prompts
```

### SQL Commands
```sql
-- Switch database
USE company;

-- Insert data
INSERT INTO employees (id, name, email) VALUES (1, "John Doe", "john@company.com");

-- Select all records
SELECT * FROM employees;

-- Select with conditions
SELECT name FROM employees WHERE id = 1;

-- Update records
UPDATE employees SET name=Jane WHERE id=1;
UPDATE employeea SET name=ahmed;

-- Delete records
DELETE FROM employees WHERE id = 1;
```

## 🔍 Data Types

| Type | Description | Validation |
|------|-------------|------------|
| `int` | Integer numbers | `/^-?[0-9]+$/` |
| `float` | Floating-point numbers | `/^-?[0-9]*\.[0-9]+$/` |
| `string` | Text data | Any string value |
| `character` | Single character | `/^.$/` |
| `email` | Email addresses | RFC-compliant email regex |

## 🏗️ Architecture

### File Storage System
- **Databases**: Stored as directories in `databases/`
- **Tables**: Each table is a file containing encoded data rows
- **Metadata**: Schema information stored in hidden `.tablename-metadata` files
- **Encoding**: All data is Base64 encoded for security and integrity

### Core Components

1. **Database Engine**: Handles database creation, connection, and management (CLI)
2. **Table Manager**: Manages table schema, creation, and deletion (CLI)
3. **Data Processor**: Handles CRUD operations with validation
4. **SQL Parser**: Processes SQL queries (INSERT, SELECT, UPDATE, DELETE, USE)
5. **Validation Layer**: Ensures data integrity and type constraints


## 🙏 Acknowledgments

- **Eng. Mahmoud El-Mahmoudy** - For exceptional guidance and setting the highest educational standards
- **Ibrahim** - For outstanding collaboration and technical contributions during development

## 🔮 Future Enhancements

- [ ] Index support for faster queries
- [ ] Join operations between tables
- [ ] Backup and restore functionality
- [ ] User authentication and permissions
- [ ] Query optimization
- [ ] Transaction support with rollback
- [ ] REST API interface
- [ ] Complete DDL SQL support (CREATE, DROP, ALTER)