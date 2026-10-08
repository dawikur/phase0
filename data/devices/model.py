# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from dataclasses import dataclass
from enum import Enum
from typing import Iterator, overload


class ScreenType(str, Enum):
    MIP2 = "MIP2"
    MIP8 = "MIP8"
    MIP16 = "MIP16"
    MIP64 = "MIP64"
    LCD = "LCD"
    AMOLED = "AMOLED"


class ScreenShape(str, Enum):
    ROUND = "round"
    SEMI_ROUND = "semi-round"
    RECTANGLE = "rectangle"
    SEMI_OCTAGON = "semi-octagon"


@dataclass(frozen=True)
class Resolution:
    width: int
    height: int


@dataclass(frozen=True)
class Memory:
    watch_face: int = -1


@dataclass(frozen=True)
class Device:
    product_id: str
    resolution: Resolution
    screen_type: ScreenType
    connect_iq_id: str = ""
    memory: Memory = Memory()
    api_version: str = ""
    screen_shape: ScreenShape = ScreenShape.ROUND
    supports_touch: bool | None = None


class Devices:
    __items: list[Device]

    def __init__(self, *items: Device):
        self.__items = list(items)

    @property
    def all(self) -> list[Device]:
        return self.__items

    @property
    def mip64(self) -> list[Device]:
        return self.__with_screen_type(ScreenType.MIP64)

    @property
    def mip2(self) -> list[Device]:
        return self.__with_screen_type(ScreenType.MIP2)

    @property
    def mip8(self) -> list[Device]:
        return self.__with_screen_type(ScreenType.MIP8)

    @property
    def mip16(self) -> list[Device]:
        return self.__with_screen_type(ScreenType.MIP16)

    @property
    def amoled(self) -> list[Device]:
        return self.__with_screen_type(ScreenType.AMOLED)

    @property
    def lcd(self) -> list[Device]:
        return self.__with_screen_type(ScreenType.LCD)

    @property
    def resolutions(self) -> tuple[Resolution, ...]:
        return tuple(
            sorted(set(self.__resolutions()), key=lambda r: (r.width, r.height))
        )

    @property
    def resolution_240x240(self) -> list[Device]:
        return self.__with_resolution(Resolution(240, 240))

    @property
    def resolution_260x260(self) -> list[Device]:
        return self.__with_resolution(Resolution(260, 260))

    @property
    def resolution_280x280(self) -> list[Device]:
        return self.__with_resolution(Resolution(280, 280))

    @property
    def resolution_390x390(self) -> list[Device]:
        return self.__with_resolution(Resolution(390, 390))

    @property
    def resolution_416x416(self) -> list[Device]:
        return self.__with_resolution(Resolution(416, 416))

    @property
    def resolution_454x454(self) -> list[Device]:
        return self.__with_resolution(Resolution(454, 454))

    def __iter__(self) -> Iterator[Device]:
        return self.__items.__iter__()

    def __len__(self) -> int:
        return len(self.__items)

    @overload
    def __getitem__(self, idx: int) -> Device:
        pass  # pragma: no cover

    @overload
    def __getitem__(self, idx: slice) -> list[Device]:
        pass  # pragma: no cover

    def __getitem__(self, idx: int | slice) -> Device | list[Device]:
        return self.__items[idx]

    def __with_screen_type(self, screen_type: ScreenType) -> list[Device]:
        return [device for device in self.__items if device.screen_type == screen_type]

    def __resolutions(self) -> Iterator[Resolution]:
        for device in self.__items:
            yield device.resolution

    def __with_resolution(self, resolution: Resolution) -> list[Device]:
        return [device for device in self.__items if device.resolution == resolution]
