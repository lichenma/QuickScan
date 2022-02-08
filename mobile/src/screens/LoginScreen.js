import React, { useState } from 'react'
import { TouchableOpacity, StyleSheet, View } from 'react-native'
import { Text } from 'react-native-paper'
import Background from '../components/Background'
import Logo from '../components/Logo'
import Header from '../components/Header'
import Button from '../components/Button'
import TextInput from '../components/TextInput'
import BackButton from '../components/BackButton'
import { theme } from '../core/theme'
import { emailValidator } from '../helpers/emailValidator'
import { passwordValidator } from '../helpers/passwordValidator'
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore/lite';
import { getAuth, signInWithEmailAndPassword } from "firebase/auth";

// TODO: Replace the following with your app's Firebase project configuration
const firebaseConfig = {
  apiKey: "AIzaSyAidQ4LnvFBCBU6Q1VbTPVivfJZ_E6APbQ",
  authDomain: "quickscan-2f853.firebaseapp.com",
  projectId: "quickscan-2f853",
  storageBucket: "quickscan-2f853.appspot.com",
  messagingSenderId: "361465475773",
  appId: "1:361465475773:web:45dc4aace1a0962ffbbdd4",
  measurementId: "G-V91KRP3H7K"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const auth = getAuth();

function loginValidator(email, password) {
  signInWithEmailAndPassword(auth, email, password)
  .then((userCredential) => {
    // Signed in 
    const user = userCredential.user;
    // ...
    return 'loggedin'
  })
  .catch((error) => {
    const errorCode = error.code;
    const errorMessage = error.message;
    return "Incorrect email or password."
  });
}

export default function LoginScreen({ navigation }) {
  const [email, setEmail] = useState({ value: '', error: '' })
  const [password, setPassword] = useState({ value: '', error: '' })

  const onLoginPressed = () => {
    const emailError = emailValidator(email.value)
    const passwordError = passwordValidator(password.value)
    const loginError = loginValidator(email.value, password.value)
    console.log(loginError)
    if (emailError || passwordError) {
      setEmail({ ...email, error: emailError })
      setPassword({ ...password, error: passwordError })
      return
    }
    if (typeof loginError == undefined || loginError == null) {
      setEmail({ ...email, error: "trash" })
      setPassword({ ...password, error: "garbage" })
      return
    }
    navigation.reset({
      index: 0,
      routes: [{ name: 'Dashboard' }],
    })
  }

  return (
    <Background>
      <BackButton goBack={navigation.goBack} />
      <Logo />
      <Header>Welcome back.</Header>
      <TextInput
        label="Email"
        returnKeyType="next"
        value={email.value}
        onChangeText={(text) => setEmail({ value: text, error: '' })}
        error={!!email.error}
        errorText={email.error}
        autoCapitalize="none"
        autoCompleteType="email"
        textContentType="emailAddress"
        keyboardType="email-address"
      />
      <TextInput
        label="Password"
        returnKeyType="done"
        value={password.value}
        onChangeText={(text) => setPassword({ value: text, error: '' })}
        error={!!password.error}
        errorText={password.error}
        secureTextEntry
      />
      <View style={styles.forgotPassword}>
        <TouchableOpacity
          onPress={() => navigation.navigate('ResetPasswordScreen')}
        >
          <Text style={styles.forgot}>Forgot your password?</Text>
        </TouchableOpacity>
      </View>
      <Button mode="contained" onPress={onLoginPressed}>
        Login
      </Button>
      <View style={styles.row}>
        <Text>Don’t have an account? </Text>
        <TouchableOpacity onPress={() => navigation.replace('RegisterScreen')}>
          <Text style={styles.link}>Sign up</Text>
        </TouchableOpacity>
      </View>
    </Background>
  )
}

const styles = StyleSheet.create({
  forgotPassword: {
    width: '100%',
    alignItems: 'flex-end',
    marginBottom: 24,
  },
  row: {
    flexDirection: 'row',
    marginTop: 4,
  },
  forgot: {
    fontSize: 13,
    color: theme.colors.secondary,
  },
  link: {
    fontWeight: 'bold',
    color: theme.colors.primary,
  },
})
