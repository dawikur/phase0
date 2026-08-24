# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from dataclasses import dataclass
from enum import Enum
from typing import Iterator, overload


class ScreenType(str, Enum):
    MIP64 = "MIP64"
    AMOLED = "AMOLED"


@dataclass(frozen=True)
class Resolution:
    width: int
    height: int


@dataclass(frozen=True)
class Device:
    product_id: str
    resolution: Resolution
    screen_type: ScreenType
    connect_iq_id: str = ""
    total_memory: int = -1


class Devices:
    __items: tuple[Device, ...]

    def __init__(self, items: list[Device]):
        self.__items = tuple(items)

    @property
    def all(self) -> tuple[Device, ...]:
        return self.__items

    @property
    def mip64(self) -> tuple[Device, ...]:
        return self.__with_screen_type(ScreenType.MIP64)

    @property
    def amoled(self) -> tuple[Device, ...]:
        return self.__with_screen_type(ScreenType.AMOLED)

    @property
    def resolutions(self) -> tuple[Resolution, ...]:
        return tuple(
            sorted(set(self.__resolutions()), key=lambda r: (r.width, r.height))
        )

    @property
    def resolution_240x240(self) -> tuple[Device, ...]:
        return self.__with_resolution(Resolution(240, 240))

    @property
    def resolution_260x260(self) -> tuple[Device, ...]:
        return self.__with_resolution(Resolution(260, 260))

    @property
    def resolution_280x280(self) -> tuple[Device, ...]:
        return self.__with_resolution(Resolution(280, 280))

    @property
    def resolution_390x390(self) -> tuple[Device, ...]:
        return self.__with_resolution(Resolution(390, 390))

    @property
    def resolution_416x416(self) -> tuple[Device, ...]:
        return self.__with_resolution(Resolution(416, 416))

    @property
    def resolution_454x454(self) -> tuple[Device, ...]:
        return self.__with_resolution(Resolution(454, 454))

    def __iter__(self) -> Iterator[Device]:
        return self.__items.__iter__()

    def __len__(self) -> int:
        return len(self.__items)

    @overload
    def __getitem__(self, idx: int) -> Device:
        pass

    @overload
    def __getitem__(self, idx: slice) -> tuple[Device, ...]:
        pass

    def __getitem__(self, idx: int | slice) -> Device | tuple[Device, ...]:
        return self.__items[idx]

    def __with_screen_type(self, screen_type: ScreenType) -> tuple[Device, ...]:
        return tuple(
            device for device in self.__items if device.screen_type == screen_type
        )

    def __resolutions(self) -> Iterator[Resolution]:
        for device in self.__items:
            yield device.resolution

    def __with_resolution(self, resolution: Resolution) -> tuple[Device, ...]:
        return tuple(
            device for device in self.__items if device.resolution == resolution
        )
