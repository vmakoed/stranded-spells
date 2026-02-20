class_name MapConfiguration
extends Node


enum Direction {UP, DOWN, LEFT, RIGHT}


const ROOM_CONNECTIONS = {
    "02": {
        Direction.RIGHT: "33"
    },
    "11": {
        Direction.UP: "24",
        Direction.RIGHT: "23"
    },
    "12": {
        Direction.UP: "13",
        Direction.RIGHT: "11",
        Direction.DOWN: "20"
    },
    "13": {
        Direction.RIGHT: "42",
        Direction.DOWN: "31"
    },
    "20": {
        Direction.UP: "21"
    },
    "21": {
        Direction.UP: "22",
        Direction.DOWN: "20",
        Direction.LEFT: "02"
    },
    "22": {
        Direction.DOWN: "21"
    },
    "23": {
        Direction.UP: "12",
        Direction.RIGHT: "21",
        Direction.LEFT: "32"
    },
    "24": {
        Direction.DOWN: "12"
    },
    "31": {
        Direction.UP: "32"
    },
    "32": {
        Direction.UP: "32",
        Direction.RIGHT: "21",
        Direction.DOWN: "11"
    },
    "33": {
        Direction.DOWN: "20",
        Direction.LEFT: "13"
    },
    "42": {
        Direction.LEFT: "23"
    }
}
