from flask import Flask, render_template

app = Flask(__name__)
# app.py

@app.route('/')
def home():
    return render_template('index.html', name='Muhammad Ahmad Amir')

@app.route('/projects')
def projects():
    projects_data = [
        {
            'title': 'E-Commerce Platform',
            'description': 'Built a full-stack e-commerce website using Flask and MySQL',
            'technologies': ['Flask', 'MySQL', 'HTML/CSS', 'JavaScript'],
            'link': '#'
        },
        {
            'title': 'Task Management App',
            'description': 'A web-based task management application with user authentication',
            'technologies': ['Flask', 'SQLite', 'Bootstrap'],
            'link': '#'
        },
        {
            'title': 'Weather App',
            'description': 'Real-time weather application using weather API',
            'technologies': ['Flask', 'API Integration', 'JSON'],
            'link': '#'
        },
        {
            'title': 'Personal Blog',
            'description': 'Dynamic blog platform with comments and categories',
            'technologies': ['Flask', 'PostgreSQL', 'Jinja2'],
            'link': '#'
        }
    ]
    return render_template('projects.html', projects=projects_data)

if __name__ == '__main__':
    app.run(debug=True)