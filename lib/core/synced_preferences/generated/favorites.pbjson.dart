// This is a generated file - do not edit.
//
// Generated from favorites.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use syncedPreferencesDescriptor instead')
const SyncedPreferences$json = {
  '1': 'SyncedPreferences',
  '2': [
    {
      '1': 'favorites',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.FavoritesState',
      '10': 'favorites'
    },
  ],
};

/// Descriptor for `SyncedPreferences`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncedPreferencesDescriptor = $convert.base64Decode(
    'ChFTeW5jZWRQcmVmZXJlbmNlcxJICglmYXZvcml0ZXMYKCABKAsyKi5mbHV4ZXIudXNlci5wcm'
    'VmZXJlbmNlcy52MS5GYXZvcml0ZXNTdGF0ZVIJZmF2b3JpdGVz');

@$core.Deprecated('Use favoritesStateDescriptor instead')
const FavoritesState$json = {
  '1': 'FavoritesState',
  '2': [
    {
      '1': 'channels',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.FavoriteChannel',
      '10': 'channels'
    },
    {
      '1': 'categories',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.FavoriteCategory',
      '10': 'categories'
    },
    {
      '1': 'collapsed_category_ids',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'collapsedCategoryIds'
    },
    {
      '1': 'hide_muted_channels',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'hideMutedChannels'
    },
    {'1': 'muted', '3': 5, '4': 1, '5': 8, '10': 'muted'},
  ],
};

/// Descriptor for `FavoritesState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List favoritesStateDescriptor = $convert.base64Decode(
    'Cg5GYXZvcml0ZXNTdGF0ZRJHCghjaGFubmVscxgBIAMoCzIrLmZsdXhlci51c2VyLnByZWZlcm'
    'VuY2VzLnYxLkZhdm9yaXRlQ2hhbm5lbFIIY2hhbm5lbHMSTAoKY2F0ZWdvcmllcxgCIAMoCzIs'
    'LmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLkZhdm9yaXRlQ2F0ZWdvcnlSCmNhdGVnb3JpZX'
    'MSNAoWY29sbGFwc2VkX2NhdGVnb3J5X2lkcxgDIAMoCVIUY29sbGFwc2VkQ2F0ZWdvcnlJZHMS'
    'LgoTaGlkZV9tdXRlZF9jaGFubmVscxgEIAEoCFIRaGlkZU11dGVkQ2hhbm5lbHMSFAoFbXV0ZW'
    'QYBSABKAhSBW11dGVk');

@$core.Deprecated('Use favoriteChannelDescriptor instead')
const FavoriteChannel$json = {
  '1': 'FavoriteChannel',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'guild_id', '3': 2, '4': 1, '5': 9, '10': 'guildId'},
    {
      '1': 'parent_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'parentId',
      '17': true
    },
    {'1': 'position', '3': 4, '4': 1, '5': 5, '10': 'position'},
    {
      '1': 'nickname',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'nickname',
      '17': true
    },
  ],
  '8': [
    {'1': '_parent_id'},
    {'1': '_nickname'},
  ],
};

/// Descriptor for `FavoriteChannel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List favoriteChannelDescriptor = $convert.base64Decode(
    'Cg9GYXZvcml0ZUNoYW5uZWwSHQoKY2hhbm5lbF9pZBgBIAEoCVIJY2hhbm5lbElkEhkKCGd1aW'
    'xkX2lkGAIgASgJUgdndWlsZElkEiAKCXBhcmVudF9pZBgDIAEoCUgAUghwYXJlbnRJZIgBARIa'
    'Cghwb3NpdGlvbhgEIAEoBVIIcG9zaXRpb24SHwoIbmlja25hbWUYBSABKAlIAVIIbmlja25hbW'
    'WIAQFCDAoKX3BhcmVudF9pZEILCglfbmlja25hbWU=');

@$core.Deprecated('Use favoriteCategoryDescriptor instead')
const FavoriteCategory$json = {
  '1': 'FavoriteCategory',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'position', '3': 3, '4': 1, '5': 5, '10': 'position'},
  ],
};

/// Descriptor for `FavoriteCategory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List favoriteCategoryDescriptor = $convert.base64Decode(
    'ChBGYXZvcml0ZUNhdGVnb3J5Eg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEh'
    'oKCHBvc2l0aW9uGAMgASgFUghwb3NpdGlvbg==');
