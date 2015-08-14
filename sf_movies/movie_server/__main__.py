import csv

from movie import Movie
from printer import Printer

__author__ = 'budde'

if __name__ == "__main__":
    Printer.print("Starting movie server")
    Printer.print("Loading file")
    movie_dict = {}
    with open('locations.csv', newline='') as file:
        reader = csv.reader(file, delimiter=',', quotechar="\"")
        for row in reader:
            title = row[0]
            location = row[2]
            if title in movie_dict:
                movie_dict[title].locations.append(location)
            else:
                movie_dict[title] = Movie(title, [location])
    Printer.print("Generating HTML file")
