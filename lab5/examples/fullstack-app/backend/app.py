from flask import Flask, jsonify, request
from flask_cors import CORS
import mysql.connector
import os
import time

app = Flask(__name__)
CORS(app)

def get_db_connection():
    """获取数据库连接，带重试机制"""
    for i in range(30):
        try:
            conn = mysql.connector.connect(
                host=os.getenv('DB_HOST', 'db'),
                user=os.getenv('DB_USER', 'root'),
                password=os.getenv('DB_PASSWORD', 'password'),
                database=os.getenv('DB_NAME', 'appdb')
            )
            return conn
        except Exception as e:
            print(f"尝试连接数据库 ({i+1}/30): {e}")
            time.sleep(1)
    return None

@app.route('/api/health')
def health():
    """健康检查接口"""
    return jsonify({'status': 'healthy', 'message': 'Backend is running'})

@app.route('/api/users', methods=['GET'])
def get_users():
    """获取所有用户"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('SELECT * FROM users ORDER BY created_at DESC')
        users = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(users)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users', methods=['POST'])
def add_user():
    """添加新用户"""
    data = request.json
    
    if not data or 'name' not in data or 'email' not in data:
        return jsonify({'error': 'Name and email are required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('INSERT INTO users (name, email) VALUES (%s, %s)',
                       (data['name'], data['email']))
        conn.commit()
        user_id = cursor.lastrowid
        cursor.close()
        conn.close()
        return jsonify({'message': 'User added successfully', 'id': user_id}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    """删除用户"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('DELETE FROM users WHERE id = %s', (user_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'User deleted successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("Starting Flask backend...")
    print(f"DB_HOST: {os.getenv('DB_HOST', 'db')}")
    app.run(host='0.0.0.0', port=5000, debug=True)

