from datetime import datetime
from random import sample  
from jinja2 import Template

def handler(username, size):
    cur_time = datetime.now()
    random_numbers = sample(range(0, 1000000), size)
    template = Template( open('template.html', 'r').read())
    html = template.render(username = username, cur_time = cur_time, random_numbers = random_numbers)
    return {'result': html}

if __name__ == "__main__":
    username = "test"
    size = 100
    result = handler(username, size)
    print("Processing Results:")
    print(f"result: {result}")