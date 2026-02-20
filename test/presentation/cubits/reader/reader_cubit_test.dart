import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_cubit.dart';
import 'package:nhasixapp/domain/usecases/content/get_content_detail_usecase.dart';
import 'package:nhasixapp/domain/usecases/content/get_chapter_images_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/add_to_history_usecase.dart';
import 'package:nhasixapp/domain/repositories/reader_settings_repository.dart';
import 'package:nhasixapp/domain/repositories/reader_repository.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/presentation/cubits/network/network_cubit.dart';
import 'package:nhasixapp/services/image_metadata_service.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGetContentDetailUseCase extends Mock
    implements GetContentDetailUseCase {}

class MockGetChapterImagesUseCase extends Mock
    implements GetChapterImagesUseCase {}

class MockAddToHistoryUseCase extends Mock implements AddToHistoryUseCase {}

class MockReaderSettingsRepository extends Mock
    implements ReaderSettingsRepository {}

class MockReaderRepository extends Mock implements ReaderRepository {}

class MockOfflineContentManager extends Mock implements OfflineContentManager {}

class MockNetworkCubit extends Mock implements NetworkCubit {}

class MockImageMetadataService extends Mock implements ImageMetadataService {}

class MockWakelockPlusPlatformInterface extends Mock
    with MockPlatformInterfaceMixin
    implements WakelockPlusPlatformInterface {}

void main() {
  late MockGetContentDetailUseCase mockGetContentDetailUseCase;
  late MockGetChapterImagesUseCase mockGetChapterImagesUseCase;
  late MockAddToHistoryUseCase mockAddToHistoryUseCase;
  late MockReaderSettingsRepository mockReaderSettingsRepository;
  late MockReaderRepository mockReaderRepository;
  late MockOfflineContentManager mockOfflineContentManager;
  late MockNetworkCubit mockNetworkCubit;
  late MockImageMetadataService mockImageMetadataService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    final mockWakelockPlusPlatform = MockWakelockPlusPlatformInterface();
    WakelockPlusPlatformInterface.instance = mockWakelockPlusPlatform;
    when(() => mockWakelockPlusPlatform.toggle(enable: any(named: 'enable')))
        .thenAnswer((_) async {});

    mockGetContentDetailUseCase = MockGetContentDetailUseCase();
    mockGetChapterImagesUseCase = MockGetChapterImagesUseCase();
    mockAddToHistoryUseCase = MockAddToHistoryUseCase();
    mockReaderSettingsRepository = MockReaderSettingsRepository();
    mockReaderRepository = MockReaderRepository();
    mockOfflineContentManager = MockOfflineContentManager();
    mockNetworkCubit = MockNetworkCubit();
    mockImageMetadataService = MockImageMetadataService();

    when(() => mockReaderSettingsRepository.saveShowUI(any()))
        .thenAnswer((_) async {});
  });

  ReaderCubit buildCubit() {
    return ReaderCubit(
      getContentDetailUseCase: mockGetContentDetailUseCase,
      getChapterImagesUseCase: mockGetChapterImagesUseCase,
      addToHistoryUseCase: mockAddToHistoryUseCase,
      readerSettingsRepository: mockReaderSettingsRepository,
      readerRepository: mockReaderRepository,
      offlineContentManager: mockOfflineContentManager,
      networkCubit: mockNetworkCubit,
      imageMetadataService: mockImageMetadataService,
    );
  }

  group('ReaderCubit - UI Visibility Logic', () {
    blocTest<ReaderCubit, ReaderState>(
      'emits state with showUI=true when showUI() is called',
      build: () => buildCubit(),
      act: (cubit) => cubit.showUI(),
      expect: () => [
        isA<ReaderState>().having((s) => s.showUI, 'showUI', true),
      ],
    );

    blocTest<ReaderCubit, ReaderState>(
      'emits state with showUI=false when hideUI() is called',
      build: () => buildCubit(),
      act: (cubit) => cubit.hideUI(),
      expect: () => [
        isA<ReaderState>().having((s) => s.showUI, 'showUI', false),
      ],
    );

    blocTest<ReaderCubit, ReaderState>(
      'emits state with toggled showUI and calls saveShowUI when toggleUI() is called',
      build: () => buildCubit(),
      act: (cubit) => cubit.toggleUI(),
      expect: () => [
        isA<ReaderState>().having((s) => s.showUI, 'showUI', false),
      ],
      verify: (_) {
        verify(() => mockReaderSettingsRepository.saveShowUI(false)).called(1);
      },
    );
  });
}
