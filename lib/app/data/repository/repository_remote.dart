import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:wallpaper_app/app/data/data_sources/remote/api_pexels.dart';
import 'package:wallpaper_app/app/data/models/collection.dart';
import 'package:wallpaper_app/app/data/models/photo.dart';
import 'package:wallpaper_app/app/data/models/video.dart';
import 'package:wallpaper_app/app/domain/entity/category_entity.dart';
import 'package:wallpaper_app/app/domain/entity/collection_entity.dart';
import 'package:wallpaper_app/app/domain/entity/media.dart';
import 'package:wallpaper_app/app/domain/entity/photo_entity.dart';
import 'package:wallpaper_app/app/domain/entity/video_entity.dart';
import 'package:wallpaper_app/app/domain/reppository/repository_remote.dart';
import 'package:wallpaper_app/core/state/data_state.dart';

class RepositoryRemoteImpl implements RepositoryRemote {
  late ApiPexels? api;
  RepositoryRemoteImpl({this.api}) {
    api ??= ApiPexels();
  }

  @override
  Future<DataState<List<PhotoEntity>>> getCuratedPhotos(
      int page, int perPage) async {
    try {
      final response = await api!.getCuratedPhotos(page, perPage);
      if (response.statusCode == HttpStatus.ok) {
        List<PhotoEntity> medias = [];
        for (var element in response.data['photos']) {
          medias.add(Photo.fromJson(element));
        }
        return DataSuccess<List<PhotoEntity>>(medias);
      } else {
        return DataFailed(DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: response.statusMessage));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<VideoEntity>>> getPopularVideos(
      int page, int perPage) async {
    try {
      final response = await api!.getPopularVideos(page, perPage);
      if (response.statusCode == HttpStatus.ok) {
        List<VideoEntity> medias = [];
        for (var element in response.data['videos']) {
          medias.add(Video.fromJson(element));
        }
        return DataSuccess<List<VideoEntity>>(medias);
      } else {
        return DataFailed(DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: response.statusMessage));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<PhotoEntity>> getPhotoById(String id) async {
    try {
      final response = await api!.getPhotoById(id);
      if (response.statusCode == HttpStatus.ok) {
        return DataSuccess<PhotoEntity>(Photo.fromJson(response.data));
      } else {
        return DataFailed<PhotoEntity>(DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: response.statusMessage));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<PhotoEntity>>> getSearchPhotos(
      String query, int page, int perPage) async {
    try {
      print("query: $query");
      final response = await api!.getSearchPhotos(query, page, perPage);
      print("getSearchPhotos response: ${response.data}");
      if (response.statusCode == HttpStatus.ok) {
        List<PhotoEntity> medias = [];
        for (var element in response.data['photos']) {
          medias.add(Photo.fromJson(element));
        }
        return DataSuccess(medias);
      } else {
        return DataFailed(DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: response.statusMessage));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(DioException(
          requestOptions: RequestOptions(),
          message: "Error getSearchPhotos: $e"));
    }
  }

  @override
  Future<DataState<List<VideoEntity>>> getSearchVideos(
      String query, int page, int perPage) async {
    try {
      final response = await api!.getSearchVideos(query, page, perPage);
      if (response.statusCode == HttpStatus.ok) {
        List<VideoEntity> medias = [];
        for (var element in response.data['videos']) {
          medias.add(Video.fromJson(element));
        }
        return DataSuccess(medias);
      } else {
        return DataFailed(DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: response.statusMessage));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<VideoEntity>> getVideoById(String id) async {
    try {
      final response = await api!.getVideoById(id);
      if (response.statusCode == HttpStatus.ok) {
        return DataSuccess<VideoEntity>(Video.fromJson(response.data));
      } else {
        return DataFailed<VideoEntity>(DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: response.statusMessage));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<CategoryEntity>>> getPhotosCategory(
      List<CategoryEntity> titles) async {
    List<CategoryEntity> categories = [];
    for (var element in titles) {
      try {
        final response = await api!.getSearchPhotos(element.title, 1, 1);
        if (response.statusCode == HttpStatus.ok) {
          final List<dynamic> photos = response.data['photos'];
          PhotoEntity photo = Photo.fromJson(photos.first);
          String? urlImg = photo.src;
          if (urlImg != null) {
            categories.add(CategoryEntity(
                title: element.title, src: urlImg, type: element.type));
          }
        }
      } catch (e) {
        print("Error title:  ${element.title}");
        print("Lỗi getPhotosCategory: $e");
      }
    }
    return DataSuccess<List<CategoryEntity>>(categories);
  }

  @override
  Future<DataState<List<CollectionEntity>>> getCollections(
      int page, int perPage, bool getImageFirst) async {
    try {
      final response = await api!.getCollections(page, perPage);
      if (response.statusCode == HttpStatus.ok) {
        final items = response.data;
        if (items["collections"] != null) {
          print("items map: ${items["collections"].length}");
          List<CollectionEntity> collections = [];
          if (getImageFirst) {
            for (var element in items["collections"]) {
              final collection = Collection.fromJson(element);
              if (collection.title != null && collection.title!.isNotEmpty) {
                final photoResponse =
                    await getSearchPhotos(collection.title!, 1, 1);
                if (photoResponse is DataSuccess &&
                    photoResponse.data != null &&
                    photoResponse.data!.first.src != null) {
                  collection.src = photoResponse.data!.first.src;
                  collections.add(collection);
                  print("collections leght: ${collections.length}");
                } else {
                  print(photoResponse.error);
                }
              }
            }
          } else {
            for (var element in items["collections"]) {
              collections.add(Collection.fromJson(element));
            }
          }
          return DataSuccess<List<CollectionEntity>>(collections);
        } else {
          return const DataSuccess<List<CollectionEntity>>([]);
        }
      } else {
        return DataFailed<List<CollectionEntity>>(DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: response.statusMessage));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<Media>>> getMediaByCollectionId(
      String collectionId, int page, int perPer) async {
    try {
      final response =
          await api!.getMediaByCollectionId(collectionId, page, perPer);
      if (response.statusCode == HttpStatus.ok) {
        List<Media> medias = [];
        if (response.data['photos'] != null) {
          for (var element in response.data['photos']) {
            medias.add(Photo.fromJson(element));
          }
        }
        if (response.data['videos'] != null) {
          for (var element in response.data['videos']) {
            medias.add(Video.fromJson(element));
          }
        }
        if (response.data['media'] != null) {
          for (var element in response.data['media']) {
            if (element['type'] == "Video") {
              medias.add(Video.fromJson(element));
            } else {
              medias.add(Photo.fromJson(element));
            }
          }
        }

        return DataSuccess<List<Media>>(medias);
      } else {
        return DataFailed(DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: response.statusMessage));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}
