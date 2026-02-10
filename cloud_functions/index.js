const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Cloud Functions for Habit Tracker App

// Sync habit data to cloud
exports.syncHabitData = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { userId, habitState, habits, stats, timestamp } = data;

  try {
    const userDoc = admin.firestore().collection('users').doc(userId);
    const monthDoc = userDoc.collection('months').doc(`${habitState.year}-${habitState.month}`);

    await monthDoc.set({
      habitState,
      habits,
      stats,
      lastUpdated: admin.firestore.Timestamp.fromDate(new Date(timestamp)),
    }, { merge: true });

    return { success: true, message: 'Data synced successfully' };
  } catch (error) {
    console.error('Error syncing data:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error syncing data to cloud'
    );
  }
});

// Load habit data from cloud
exports.loadHabitData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { userId, year, month } = data;

  try {
    const monthDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('months')
      .doc(`${year}-${month}`)
      .get();

    if (!monthDoc.exists) {
      return { exists: false };
    }

    return { exists: true, data: monthDoc.data() };
  } catch (error) {
    console.error('Error loading data:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error loading data from cloud'
    );
  }
});

// Get historical data
exports.getHistoricalData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { userId, limitMonths = 12 } = data;

  try {
    const snapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('months')
      .orderBy('habitState.year', 'desc')
      .orderBy('habitState.month', 'desc')
      .limit(limitMonths)
      .get();

    const historicalData = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    return { historicalData };
  } catch (error) {
    console.error('Error getting historical data:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error retrieving historical data'
    );
  }
});

// Generate analytics report
exports.generateAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { userId, year, month } = data;

  try {
    // Get current month data
    const monthDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('months')
      .doc(`${year}-${month}`)
      .get();

    if (!monthDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'No data found for specified month'
      );
    }

    const monthData = monthDoc.data();
    
    // Generate analytics
    const analytics = {
      summary: {
        totalHabits: monthData.habits?.length || 0,
        activeHabits: monthData.habits?.filter(h => h.name).length || 0,
        monthlyProgress: monthData.stats?.monthlyProgress || 0,
        successRate: monthData.stats?.successRate || 0,
        currentStreak: monthData.stats?.currentStreak || 0,
      },
      habitPerformance: monthData.habits?.map(habit => ({
        name: habit.name,
        progress: habit.totalCompletions / (habit.targetGoal || 31),
        completions: habit.totalCompletions,
        goal: habit.targetGoal || 'Daily',
      })) || [],
      dailyPerformance: monthData.stats?.dailyTotals?.map((total, index) => ({
        day: index + 1,
        completions: total,
        efficiency: monthData.stats.dailyEfficiency[index],
      })) || [],
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    return { analytics };
  } catch (error) {
    console.error('Error generating analytics:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error generating analytics report'
    );
  }
});

// Backup data
exports.backupData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { userId, data: userData, timestamp } = data;

  try {
    const backupId = `backup_${Date.now()}`;
    const backupDoc = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('backups')
      .doc(backupId);

    await backupDoc.set({
      data: userData,
      timestamp: admin.firestore.Timestamp.fromDate(new Date(timestamp)),
      backupId,
    });

    return { backupId, message: 'Backup created successfully' };
  } catch (error) {
    console.error('Error creating backup:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error creating backup'
    );
  }
});

// Restore data
exports.restoreData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { userId, backupId } = data;

  try {
    const backupDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('backups')
      .doc(backupId)
      .get();

    if (!backupDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Backup not found'
      );
    }

    const backupData = backupDoc.data().data;

    // Restore the data
    const { habitState, habits, stats } = backupData;
    const monthDoc = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('months')
      .doc(`${habitState.year}-${habitState.month}`);

    await monthDoc.set({
      habitState,
      habits,
      stats,
      restoredAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { message: 'Data restored successfully' };
  } catch (error) {
    console.error('Error restoring data:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error restoring data'
    );
  }
});

// Share progress
exports.shareProgress = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { userId, year, month, includeDetails, timestamp } = data;

  try {
    const monthDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('months')
      .doc(`${year}-${month}`)
      .get();

    if (!monthDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'No data found for specified month'
      );
    }

    const monthData = monthDoc.data();
    
    // Create shareable data
    const shareableData = {
      user: context.auth.uid,
      month: `${month} ${year}`,
      summary: {
        monthlyProgress: monthData.stats?.monthlyProgress || 0,
        successRate: monthData.stats?.successRate || 0,
        currentStreak: monthData.stats?.currentStreak || 0,
        activeHabits: monthData.habits?.filter(h => h.name).length || 0,
      },
      details: includeDetails ? {
        habits: monthData.habits?.map(habit => ({
          name: habit.name,
          progress: (habit.totalCompletions / (habit.targetGoal || 31)) * 100,
          goal: habit.targetGoal || 'Daily',
        })) || [],
        dailyStats: monthData.stats?.dailyTotals || [],
      } : null,
      sharedAt: admin.firestore.Timestamp.fromDate(new Date(timestamp)),
    };

    // Store share record
    const shareId = `share_${Date.now()}`;
    await admin.firestore()
      .collection('shared_progress')
      .doc(shareId)
      .set(shareableData);

    return { shareId, shareableData };
  } catch (error) {
    console.error('Error sharing progress:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error sharing progress'
    );
  }
});

// Update user settings
exports.updateSettings = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { userId, settings } = data;

  try {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .set({
        settings,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

    return { success: true, message: 'Settings updated successfully' };
  } catch (error) {
    console.error('Error updating settings:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error updating settings'
    );
  }
});

// Get user settings
exports.getUserSettings = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { userId } = data;

  try {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    const settings = userDoc.exists ? userDoc.data()?.settings || {} : {};

    return { settings };
  } catch (error) {
    console.error('Error getting user settings:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error retrieving user settings'
    );
  }
});
